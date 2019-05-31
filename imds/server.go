package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

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

	http.HandleFunc("/metadata/identity/oauth2/token", handlerTokenIssuance)
	http.HandleFunc("/metadata/instance", handlerInstanceMetadata)
	http.HandleFunc("/", handlerDefault)

	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s:80", addr), nil))
}

// handler echoes the Path component of the requested URL.
func handlerDefault(w http.ResponseWriter, r *http.Request) {
	fmt.Printf("URL.Path = %q\n", r.URL.Path)
	fmt.Printf("URL.Path = %v\n", r)
	fmt.Fprintf(w, "URL.Path = %q\n", r.URL.Path)
}

func handlerTokenIssuance(w http.ResponseWriter, r *http.Request) {
	// "/metadata/identity/oauth2/token"
	//  /metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net%2F&client_id=5d876433-efa9-42ea-9ac3-28a920370be6
	fmt.Printf("Issue token URL.Path = %q\n", r.URL.Path)

	clientSecrets := map[string]string{
		"5d876433-efa9-42ea-9ac3-28a920370be6": "cvECM/OblEL/WOJweC0=",
	}
	aadTenant := "chgeuerfte.onmicrosoft.com"

	query := r.URL.Query()
	resource, ok := query["resource"]
	if ok {
		fmt.Printf("Resource %s\n", resource[0])
	}
	clientID, ok := query["client_id"]
	if ok {
		fmt.Printf("client_id %s\n", clientID[0])
	}

	form := url.Values{
		"grant_type":    {"client_credentials"},
		"client_id":     {clientID[0]},
		"client_secret": {clientSecrets[clientID[0]]},
		"resource":      {resource[0]},
	}
	request, err := http.NewRequest(http.MethodPost, fmt.Sprintf("https://login.microsoftonline.com/%s/oauth2/token", aadTenant), strings.NewReader(form.Encode()))
	// request, err := http.NewRequest(http.MethodPost, "http://localhost:4000/hooks/ea36cb4f-50c8-466a-b7fc-5cd7fb46a0b0", strings.NewReader(form.Encode()))
	if err != nil {
		log.Print(err)
		os.Exit(1)
	}

	// proxyUrl, _ := url.Parse("http://127.0.0.1:8888")
	var netClient = &http.Client{
		Timeout: time.Second * 10,
		// Transport: &http.Transport{
		// 	Proxy:           http.ProxyURL(proxyUrl),
		// 	TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		// },
	}
	response, err := netClient.Do(request)
	if err != nil {
		log.Print(err)
		os.Exit(1)
	}

	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		log.Print(err)
		os.Exit(1)
	}

	fmt.Println(os.Stdout, "%s", string(body))

	w.Write(body)
}

func handlerInstanceMetadata(w http.ResponseWriter, r *http.Request) {
	instance := InstanceMetadata{
		ComputeMetadata: ComputeMetadata{
			Name:                 "somevm",
			VMID:                 "c7619932-27e3-4a63-988c-460bd290ca55",
			Tags:                 "tag1:val2",
			AzEnvironment:        "AzurePublicCloud",
			SubscriptionID:       "724467b5-bee4-484b-bf13-d6a5505d2b51",
			Location:             "westeurope",
			ResourceGroupName:    "spring",
			VMSize:               "Standard_D2s_v3",
			CustomData:           "",
			OSType:               "Linux",
			Publisher:            "Canonical",
			Offer:                "UbuntuServer",
			Sku:                  "18.04-LTS",
			Version:              "18.04.201905290",
			PlacementGroupID:     "",
			PlatformFaultDomain:  "0",
			PlatformUpdateDomain: "0",
			VMScaleSetName:       "",
			Zone:                 "",
			Provider:             "Microsoft.Compute",
		},
	}

	if err := json.NewEncoder(w).Encode(instance); err != nil {
		panic(err)
	}
}

type InstanceMetadata struct {
	ComputeMetadata ComputeMetadata `json:"compute"`
	// NetworkMetadata        NetworkMetadata       `json:"network"`
}
type ComputeMetadata struct {
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
}
