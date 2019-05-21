package com.sap.concur.demo.aaddemo;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.ui.Model;

@RestController
public class HelloController {
   @Value("${spring.datasource.url}")
   private String myDatabaseConnectionStringFromKeyVault;

   @Autowired
   @PreAuthorize("hasRole('christian')")
   @RequestMapping(path = "/", method = RequestMethod.GET)
   public String isSomeChristian() {
      return "Welcome, you're in the 'christian' Azure AD group: " + myDatabaseConnectionStringFromKeyVault;
   }

   @PreAuthorize("isAuthenticated()")
   @RequestMapping(path = "/isAuthenticated", method = RequestMethod.GET)
   public String isAuthenticated() {
      Authentication auth = SecurityContextHolder.getContext().getAuthentication();
      return "Welcome, you're authenticated: " + auth.getPrincipal().toString();
   }
}
