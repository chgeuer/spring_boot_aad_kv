package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"strings"
	"time"
)

func readJSONConfig(filename string) *config {
	file, _ := ioutil.ReadFile(filename)
	var data config
	_ = json.Unmarshal([]byte(file), &data)
	return &data
}

func main() {
	// netsh := "C:\\Windows\\System32\\netsh.exe"
	// inf := "vEthernet (Default Switch)"
	addr := "169.254.169.254"

	// fmt.Printf("Create IP address")
	// c := exec.Command(netsh, "interface", "ipv4", "add", "address", fmt.Sprintf("name=\"%s\"", inf), fmt.Sprintf("address=\"%s\"", addr))
	// if err := c.Run(); err != nil {
	// 	fmt.Println("Error: ", err)
	// }

	// sigChan := make(chan os.Signal, 1)
	// signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	// go func() {
	// 	<-sigChan

	// 	fmt.Printf("Delete IP address")

	// 	c := exec.Command(netsh, "interface", "ipv4", "delete", "address", fmt.Sprintf("name=\"%s\"", inf), fmt.Sprintf("address=\"%s\"", addr))
	// 	if err := c.Run(); err != nil {
	// 		fmt.Println("Error: ", err)
	// 	}

	// 	os.Exit(0)
	// }()

	// curl -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-
	// {"compute":{"azEnvironment":"AzurePublicCloud","customData":"","location":"westeurope","name":"v","offer":"UbuntuServer","osType":"Linux","placementGroupId":"","plan":{"name":"","product":"","publisher":""},"platformFaultDomain":"0","platformUpdateDomain":"0","provider":"Microsoft.Compute","publicKeys":[{"keyData":"ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAk/ViUPrGp7KoJLuN2PgofgMyw7SN9zfLYFDDR0TRYa8cOvJlE8NdZYt6Oqa4aL/fslKr9bmlMCdawhZRL7sHccIIS0I0zG7iD15rQL3/Y5aZOf3ML+bebpSj+SE5OeHT9iobgsYpK8gq72d8tmZZAfKhx6fRJsgC2j2xXH/GveoZ5GkHnhJUYuYPmNjEb/PK7LT43XuP+E9Rderr3LPUTuBeGVW9do0HS7X8I2uTn0+BqgkZLOO4FCnSXxh1u6fuD++ZgOZVmB6Q1xEdHSA7LLnPkjDZqbWezLIh5cSdNPUW2JG7tMxQTAZzVoNMb6vAVsfslB16rqZQ21EdIq+0pw== chgeuer-dcos-1","path":"/home/chgeuer/.ssh/authorized_keys"}],"publisher":"Canonical","resourceGroupName":"spring","sku":"18.04-LTS","subscriptionId":"724467b5-bee4-484b-bf13-d6a5505d2b51","tags":"tag1:val2","version":"18.04.201905290","vmId":"c7619932-27e3-4a63-988c-460bd290ca55","vmScaleSetName":"","vmSize":"Standard_D2s_v3","zone":""},"network":{"interface":[{"ipv4":{"ipAddress":[{"privateIpAddress":"10.0.0.4","publicIpAddress":"13.81.2.149"}],"subnet":[{"address":"10.0.0.0","prefix":"24"}]},"ipv6":{"ipAddress":[]},"macAddress":"000D3A48FA8D"}]}}

	cfg := readJSONConfig("config.json")

	http.HandleFunc("/metadata/identity/oauth2/token", cfg.handlerTokenIssuance)
	http.HandleFunc("/metadata/instance/compute", cfg.returnData(cfg.InstanceMetadata.ComputeMetadata))
	http.HandleFunc("/metadata/instance/network", cfg.returnData(cfg.InstanceMetadata.NetworkMetadata))
	http.HandleFunc("/metadata/instance", cfg.returnData(cfg.InstanceMetadata))

	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s:80", addr), nil))
}

func emittedErrorBecauseMissingMetadata(w http.ResponseWriter, r *http.Request) bool {
	if d := r.Header["Metadata"]; len(d) != 1 || d[0] != "true" {
		errorMessage := struct {
			Message string `json:"error"`
		}{Message: "Bad request. Required metadata header not specified"}

		if err := json.NewEncoder(w).Encode(errorMessage); err != nil {
			panic(err)
		}
		return true
	}
	return false
}

func (cfg *config) returnData(data interface{}) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		if emittedErrorBecauseMissingMetadata(w, r) {
			return
		}
		if err := json.NewEncoder(w).Encode(data); err != nil {
			panic(err)
		}
	}
}

func (cfg *config) handlerTokenIssuance(w http.ResponseWriter, r *http.Request) {
	if emittedErrorBecauseMissingMetadata(w, r) {
		return
	}

	query := r.URL.Query()
	form := url.Values{"grant_type": {"client_credentials"}}

	if resource, ok := query["resource"]; ok && len(resource) == 1 {
		form.Add("resource", resource[0])
	}

	if clientID, ok := query["client_id"]; ok && len(clientID) == 1 && clientID[0] != "" {
		if clientSecret, ok := cfg.ServicePrincipalKeys[clientID[0]]; ok {
			form.Add("client_id", clientID[0])
			form.Add("client_secret", clientSecret)
		}
	} else {
		// if no client_id is specified, simply take the first entry
		for id, key := range cfg.ServicePrincipalKeys {
			form.Add("client_id", id)
			form.Add("client_secret", key)
			break
		}
	}

	requestBody := strings.NewReader(form.Encode())

	aadURL := fmt.Sprintf("https://login.microsoftonline.com/%s/oauth2/token", cfg.TenantID)
	request, err := http.NewRequest(http.MethodPost, aadURL, requestBody)
	if err != nil {
		log.Fatal(err)
		return
	}

	var netClient = newHTTPClient(false)

	response, err := netClient.Do(request)
	if err != nil {
		log.Fatal(err)
		return
	}

	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		log.Fatal(err)
		return
	}

	fmt.Printf("%s", string(body))

	w.Write(body)
}

func newHTTPClient(useFiddler bool) *http.Client {
	var netClient = &http.Client{
		Timeout: time.Second * 10,
	}
	if useFiddler {
		proxyURL, _ := url.Parse("http://127.0.0.1:8888")
		netClient.Transport = &http.Transport{
			Proxy:           http.ProxyURL(proxyURL),
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
	}
	return netClient
}

type config struct {
	TenantID             string            `json:"tenantID"`
	ServicePrincipalKeys map[string]string `json:"servicePrincipals"`
	InstanceMetadata     struct {
		ComputeMetadata struct {
			AzEnvironment        string `json:"azEnvironment"`
			Name                 string `json:"name"`
			Location             string `json:"location"`
			CustomData           string `json:"customData"`
			OSType               string `json:"osType"`
			Offer                string `json:"offer"`
			PlacementGroupID     string `json:"placementGroupId"`
			PlatformFaultDomain  string `json:"platformFaultDomain"`
			PlatformUpdateDomain string `json:"platformUpdateDomain"`
			Provider             string `json:"provider"`
			Publisher            string `json:"publisher"`
			ResourceGroupName    string `json:"resourceGroupName"`
			Sku                  string `json:"sku"`
			SubscriptionID       string `json:"subscriptionId"`
			Tags                 string `json:"tags"`
			Version              string `json:"version"`
			VMID                 string `json:"vmId"`
			VMScaleSetName       string `json:"vmScaleSetName"`
			VMSize               string `json:"vmSize"`
			Zone                 string `json:"zone"`
		} `json:"compute"`
		NetworkMetadata struct {
			Interface []struct {
				Ipv4 struct {
					IPAddress []struct {
						PrivateIPAddress string `json:"privateIpAddress"`
						PublicIPAddress  string `json:"publicIpAddress"`
					} `json:"ipAddress"`
					Subnet []struct {
						Address string `json:"address"`
						Prefix  string `json:"prefix"`
					} `json:"subnet"`
				} `json:"ipv4"`
				Ipv6 struct {
					IPAddress []interface{} `json:"ipAddress"`
				} `json:"ipv6"`
				MacAddress string `json:"macAddress"`
			} `json:"interface"`
		} `json:"network"`
	} `json:"metadata"`
}
