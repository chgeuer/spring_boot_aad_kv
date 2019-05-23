/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 * Licensed under the MIT License. See LICENSE in the project root for
 * license information.
 */

package com.sap.concur.demo.aaddemo;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.ui.Model;

import java.util.Optional;

@RestController
public class HelloController {
   @Autowired
   private PetRepository petRepository;

   @Value("${spring.datasource.url}")
   private String spring_datasource_url;

   @Autowired
   @PreAuthorize("hasRole('christian')")
   @RequestMapping(path = "/", method = RequestMethod.GET)
   public String isSomeChristian() {
      return "Welcome, you're in the 'christian' Azure AD group URL: " + 
        "The full connection string for the database is " 
        + spring_datasource_url;
   }

   @PreAuthorize("isAuthenticated()")
   @RequestMapping(path = "/claims", method = RequestMethod.GET)
   public String showClaims() {
      Authentication auth = SecurityContextHolder.getContext().getAuthentication();
      return "Welcome, you're authenticated. Here's what I know about you: " + auth.getPrincipal().toString();
   }

   @PreAuthorize("isAuthenticated()")
   @RequestMapping(path = "/pet/create", method = RequestMethod.POST)
   public @ResponseBody String createPet(@RequestBody Pet pet) {
       petRepository.save(pet);
       return String.format("Added %s", pet);
   }

   @RequestMapping(path = "/pet/", method = RequestMethod.GET)
   public @ResponseBody Iterable<Pet> getAllPets() {
       return petRepository.findAll();
   }

   @RequestMapping(path = "/pet/{id}", method = RequestMethod.GET)
   public @ResponseBody Optional<Pet> getPet(@PathVariable Integer id) {
       return Optional.ofNullable(petRepository.findById(id));
   }

   @RequestMapping(path = "/pet/{id}", method = RequestMethod.DELETE)
   public @ResponseBody String deletePet(@PathVariable Integer id) {
       petRepository.deleteById(id);
       return "Deleted " + id;
   }
}
