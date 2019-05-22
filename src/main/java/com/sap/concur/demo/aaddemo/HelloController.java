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
   private String spring_datasource_url;
   @Value("${spring.datasource.username}")
   private String spring_datasource_username;
   @Value("${spring.datasource.password}")
   private String spring_datasource_password;

   @Autowired
   @PreAuthorize("hasRole('christian')")
   @RequestMapping(path = "/", method = RequestMethod.GET)
   public String isSomeChristian() {
      return "Welcome, you're in the 'christian' Azure AD group\nURL: " + spring_datasource_url + "\nuser: " + spring_datasource_username + "\npass: " + spring_datasource_password;
   }

   @PreAuthorize("isAuthenticated()")
   @RequestMapping(path = "/claims", method = RequestMethod.GET)
   public String showClaims() {
      Authentication auth = SecurityContextHolder.getContext().getAuthentication();
      return "Welcome, you're authenticated. Here's what I know about you: " + auth.getPrincipal().toString();
   }
}
