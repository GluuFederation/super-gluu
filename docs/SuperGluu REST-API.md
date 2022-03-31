# API (SuperGluu)
## Authentication flow

1. Get configuration
```sh
URL https://latest431.gluu.org/.well-known/fido-configuration, 
Method GET, 
Parameters - nil
```
Response:
```sh
{  
    "version" : "2.0",  
    "issuer" : "https://latest431.gluu.org",  
    "registration_endpoint" : "https://latest431.gluu.org/oxauth/restv1/fido/u2f/registration", 
    "authentication_endpoint" : "https://latest431.gluu.org/oxauth/restv1/fido/u2f/authentication"
}
```

2. Get authentication data for corresponding user name and application
```sh
URL https://latest431.gluu.org/oxauth/restv1/fido/u2f/authentication, 
Method GET, 
Parameters: 
    session_id -> 5984ee2a-b935-45f4-b1bd-a6d2db028ed5, 
    username -> NazarFewAccounts, 
    application -> https://latest431.gluu.org/casa
```

Response:
```sh
{
    "authenticateRequests": 
    [
        {
            "challenge":"YATGb2fTDYu_5-wegWZgBHKUiVNCC2eIpDeFHp64CtI",
            "appId":"https://latest431.gluu.org/casa",
            "keyHandle":"xMBmz835AYVBRtKr208gC8AqoYH_50dCn_s5M57yTcox7uXAsMyZre6Aw9YGP80EJlND9VpPom_AKPbzBM5kMg",
            "version":"U2F_V2"
        },
        {
            "challenge":"YATGb2fTDYu_5-wegWZgBHKUiVNCC2eIpDeFHp64CtI",
            "appId":"https://latest431.gluu.org/casa",
            "keyHandle":"JrIF1zRpUSdgzMtgSBua1jkd-SpIFuFiMJ91uyR__QbdJ9IjLpCEKHzNuqpPfWlmvEk5vL2MO0EC4vEGuGwuzA",
            "version":"U2F_V2"
        }
    ]
}
```

3. Proceed authentication
```sh
    URL https://latest431.gluu.org/oxauth/restv1/fido/u2f/authentication, 
    Method POST, 
    Parameters: 
        username: NazarFewAccounts, 
        tokenResponse: 
                        {
                            "signatureData":"AQAAAAswRAIgcBsBZsQGDxtNXtC8okozYfiEFqIvUiN3wsoLM4irMkYCIG6hb06XDSg-1s-sfhTlOgF6rY5KfgkyBt3kdguky6TX",
                            "clientData":"eyJ0eXAiOiJuYXZpZ2F0b3IuaWQuZ2V0QXNzZXJ0aW9uIiwiY2hhbGxlbmdlIjoiYTZocElEUU9iMjVkNDYwQlZNaVAxZGtFTHZjR3libkF6SUNwWlVDOEFKQSIsIm9yaWdpbiI6Imh0dHBzOlwvXC9sYXRlc3Q0MzEuZ2x1dS5vcmdcL2Nhc2EifQ",
                            "keyHandle":"xMBmz835AYVBRtKr208gC8AqoYH_50dCn_s5M57yTcox7uXAsMyZre6Aw9YGP80EJlND9VpPom_AKPbzBM5kMg"
                        }
```

Response:
```sh
    {
        "status":"success",
        "challenge":"a6hpIDQOb25d460BVMiP1dkELvcGybnAzICpZUC8AJA"
    }
```
