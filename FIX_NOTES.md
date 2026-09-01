# MxxHub v0.3.1 build fix

Fixes the GitHub Actions integration:

- uses the MxxHub project/scheme instead of the old MexxBox names
- prepares WineGlass + blink before XcodeGen validates external source paths
- uses XcodeGen `dependencies` for iOS SDK frameworks
- tolerates current blink trees that do not ship `config.h.ios`
- verifies the runtime archive/object exist before generating the Xcode project
