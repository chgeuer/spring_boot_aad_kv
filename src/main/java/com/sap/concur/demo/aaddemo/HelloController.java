package com.sap.concur.demo.aaddemo;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.ui.Model;

@RestController
public class HelloController {
   @Autowired
   @PreAuthorize("hasRole('Users')")
   @RequestMapping(path = "/", method = RequestMethod.GET)
   public String helloWorld() {
      return "Hello World!";
   }

   @PreAuthorize("hasRole('christian')")
   @RequestMapping("/christian")
   public String groupChristian() {
      return "Hello Christian";
   }
}
