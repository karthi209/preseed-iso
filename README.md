# PreSeedISO

## Overview

`PreSeedISO.ps1` is a PowerShell script designed to automate the creation of a preseeded ISO image for unattended installations of operating systems. This script simplifies the process of integrating preseed files and other necessary configurations into an ISO image.

## Features

- Automates the creation of preseeded ISO images
- Integrates preseed files for unattended installations

## Requirements

- Windows PowerShell 5.1 or later
- [Windows ADK](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) - the powershell script requires the `oscdimg` component of the Windows ADK, but it's just easier to install as a kit

## Usage

1. Clone the repository to your local machine:
    ```sh
    git clone https://github.com/karthi209/preseed-iso.git
    ```

2. Navigate to the script directory:
    ```sh
    cd preseed-iso
    ```

3. Run the script:
    ```sh
    .\PreSeedISO.ps1
    ```

## Parameters

- Make sure to place your Debian ISO inside the repository - the script will look for an .ISO file inside here, if you have multiple ISO files in this folder the script will chose the first one in alphabetical order.

- You can update the preseed.cfg as per your requirement - the default as generic values that should be good enough for most test VMs.

- Provide the disk letter when it prompts - give any disk letter that's not currently in use.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For any questions or issues, please open an issue on the [GitHub repository](https://github.com/karthi209/preseed-iso/issues).
