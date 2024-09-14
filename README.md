# ldryt's personal infrastructure

This repository contains my personal Nix flake, scripts and Terraform code for managing my environment and infrastructure.

> [!NOTE]
> This project is tailored to my needs and may not be suitable for direct use. Feel free to use it as a reference for your own setup. I update this repository as my needs change, it's a living project that evolves with my workflow and equipment.

## Why ?
*why not?*
Really, I could stick with my Arch install, Ansible playbooks, and bash scripts. But I chose this approach for several reasons:
-   **Reproducibility**: It ensures my systems can be replicated precisely across machines and time. For example, I'm able to replicate one machine in a VM  to test it before deployment. No more "it works on my machine" issues.
-   **Version Control**: My infrastructure lives in code. I track changes, roll back, and keep a setup history.
-   **Declarativeness**: Nix and Terraform let me define my systems' desired state. This cuts a large amount of errors and eases upkeep.
-   **Modularity**: I share configs between hosts while keeping machine-specific settings apart.
-   **Ecosystem**: Nix has a huge package and services library. I love it.
-   **Consistency**: All my machines get identical dev environments. No more system differences.

This method demands more effort. But it gives me a robust, flexible system that grows with my needs. It keeps my machines stable and predictable.

## Key Features

-   **[Nix flake](https://zero-to-nix.com/concepts/flakes)**
-   **[Home Manager](https://nixos.wiki/wiki/Home_Manager)**
-   **[Custom Modules](./modules/)**
-   **[Terraform](https://developer.hashicorp.com/terraform/intro)**
-   **[SOPS](https://getsops.io/)**

## Project Structure

The repository is organized as follows:

-   `hosts`: Configuration files for each host
-   `modules`: Reusable Nix modules for shared configurations
-   `users`: User-specific configurations (using home-manager)

## Contributing

I'm all ears when it comes to improvements, so don't be shy! You're more than welcome to open a pull request if you think it'll help :)
