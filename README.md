# spring_boot_aad_kv

Small demo of a dockerized Spring Boot web application with Azure AD and KeyVault.

This demo shows multiple aspects:

- It's a Spring Boot-based web application
- The web app is configured solely via environment variables (to be a good Docker citizen) and Azure KeyVault for confidential values
  - Specifically, the SQL Azure connection information (connection string, username and password) come in from KeyVault. 
- The web app authenticates users via Azure AD.
  - On the [/](http://localhost:8080/) endpoint, it enforces group membership. 
  - On the [/claims](http://localhost:8080/claims) endpoint, it prints out the user's security token's properties. 
  - On `GET /pet`, `POST /pet/create`, `GET /pet/123` and `DELETE /pet/123` we authenticate the user, and interact with SQL Azure in the back. 

## misc links

- [Tutorial: Secure a Java web app using the Spring Boot Starter for Azure Active Directory](https://docs.microsoft.com/en-us/java/azure/spring-framework/configure-spring-boot-starter-java-app-with-azure-active-directory?view=azure-java-stable)
- [PetController](https://github.com/Azure-Samples/spring-data-jdbc-on-azure/blob/master/src/main/java/com/microsoft/azure/samples/spring/PetController.java)
- [Azure Key Vault Secrets Spring Boot Starter Sample](https://github.com/microsoft/azure-spring-boot/tree/master/azure-spring-boot-samples/azure-keyvault-secrets-spring-boot-sample)
- [Bootiful Azure: SQL-based data access with Microsoft SQL Server (2/6)](https://spring.io/blog/2019/01/07/bootiful-azure-sql-based-data-access-with-microsoft-sql-server-2-6)
