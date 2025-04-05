# Local Installation

## Requirements
- Windows

## Step By Step
- Download and unzip the latest version from https://ifgamesh.itch.io/ifgamesh-community-kiosk or https://github.com/JonasMumm/if-game-sh-community-launcher/releases.
- Run `IFgamesSH Community Kiosk Setup.bat` from the unzipped folder to configure your launcher. You can also run it after the first setup to change your configuration.
- When first opening `IFgamesSH Community Kiosk Setup.bat`, all status boxes appear red. Configure each option from top to bottom until all status boxes have turned green. <img src="ReadMeSrc/setup_uninitialized.png"> Each Category also has an expandable info box to help you get set up.
- ### Butler
- Butler is a commandline tool to install and manage games via the itch.io backend. It is required to do anything else with the launcher. Select `Install Butler` to download and install the latest version to `%APPDATA%/IFgameSH Community Kiosk/butler`. Downloading and extracting the files may take a minute. Plese be patient while the download is running. After butler has been downloaded and extracted. The Butler status box will turn green. <img src="ReadMeSrc/setup_butler_initialized.png">
- ### Profile
- You need to log in with an itch.io profile to access itch-collections to pull games from and to access download-keys associated with that profile for paid games. Loging in is done via an API key. You can generate and access API Keys for your profile at https://itch.io/user/settings/api-keys.
- ### Collection
- Itch-collections are used to supply the games accessible in the kiosk. Choosing a collection is necessary to download any games. Once you have chosen a collection, hit the `Install / Update Games` button to install or update games. You can change your collection later if you want to exhibit a different set of games. Jumping back and forth between collections keeps all games installed and doesn't require re-downloading games.
- ### Web Browser Launch
- Only required when attempting to launch browser-based games. Setting up the browser launch options is a two-step process. The first step involves choosing the browser mode. You can choose between selecting predefined GoogleChrome or MicrosoftEdge profiles, which come with kiosk-friendly launch options. Alternatively, you can supply a command to be executed in cmd.exe to launch a diffrenet browser with custom options. The second step involves specifying the path to your browser's .exe file if you've choosen GoogleChrome or MicrosoftEdge mode. If you selected the CommandLine mode, you will have to specify the command to run.