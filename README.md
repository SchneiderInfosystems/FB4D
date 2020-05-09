# FB4D – The OpenSource Cross-Platform Library for _Firebase_

The _Google Firebase Cloud Database_ is used in many mobile and web applications worldwide and there are well-documented libraries for many languages and platforms. For Delphi, the cross-platform library **FB4D** supports the _Firebase Realtime Database_, the _Firestore Database_, the _Firebase Storage_ (for file storage), and _Firebase Functions_ (for calling server functions). For authentication, **FB4D** currently supports email/password authentication and anonymous login. 

The library builds on the _Firebase REST-API_ and provides all functionality with synchronous and asynchronous methods for the usage within GUI application, services and background threads. Both frameworks _VCL_ and _Firemonkey_ are supported. The library is a pure source code library and relies on class interfaces. For clean and short application code it supports fluent interface design.

### Wiki

This project offers a [wiki](https://github.com/SchneiderInfosystems/FB4D/wiki). Four example applications and a [Getting-Started](https://github.com/SchneiderInfosystems/FB4D/wiki/Getting-Started-with-FB4D) on the wiki will help you to start working with the library. For more detailed questions, the [interface reference](https://github.com/SchneiderInfosystems/FB4D/wiki/FB4D-Interface-Reference) will provide the answers you need.

You can find more learning videos on the following [YouTube channel](https://www.youtube.com/channel/UC3qSIUzdGqoZA8hcA31X0Og).

### Prerequisites

This library requires at least Delphi 10 Seattle. The sample projects are developed with Delphi 10.2 Tokio and are ready for Delphi 10.3 Rio Update 3. 
#### Hint: Delphi 10.3 Update 1 is not longer supported because of an issue in the RTL. 

### Supported Platforms

**FB4D** is developed in pure object pascal and can be used with _Firemonkey_ on all supported plattforms. The library and its sample projects are currently tested with Win64/Win32, Mac32, iOS64 and Android. (Hint to mobile platforms: The TokenJWT to perform the token verifcation requires the installation of the OpenSSL libraries and is not tested yet). 

### Submodules

For authorization token verification and token content extraction this library uses the Delphi JOSE JWT library. Thank you Paolo Rossi for your great library!

https://github.com/paolo-rossi/delphi-jose-jwt

![Logo FB4D](https://github.com/SchneiderInfosystems/FB4D/wiki/logoFB4D.png)
