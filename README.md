# StickManBadminton-on-FPGA

A Two-Player Interactive Game on FPGA

## 📋 Overview

StickManBadminton-on-FPGA is a two-player interactive badminton game implemented on an FPGA. Players control stick figure characters to play badminton against each other in a digital hardware environment.

For a detailed overview of the project, including design concepts, implementation details, and demonstrations, please refer to the presentation slides:
[StickManBadminton Presentation](https://docs.google.com/presentation/d/1zoz6aC_Ih6Uw6YF6MzBEiaykrYxHg3aTIHqkL9wZQng/edit?usp=sharing)

### Demo Video
Check out the gameplay demonstration on YouTube:
[StickManBadminton Demo](https://www.youtube.com/your_video_link_here)

### Development Environment
- **FPGA Board**: DE1-SoC
- **Software**: Quartus Prime 18.1
- **Display**: VGA Monitor
- **User Input**: PS/2 Controller

The game runs directly on the DE1-SoC board. After compiling the Verilog files in Quartus Prime 18.1, the bitstream is uploaded to the FPGA board, which then drives a VGA monitor to display the game. Players use a PS/2 controller to move the on-screen stickman characters and play badminton against each other.

## 📁 Repository Contents

- **Verilog Source Files (.v)**: All the necessary Verilog modules for the game's logic, rendering, and input handling.

**Note**: This repository does not include configuration files for Quartus or other project-related files. You can create your own Quartus project and add these .v files as source modules.

## 🚀 Getting Started

1. Clone this repository or download the .v files.
2. Create a new project in Quartus Prime 18.1 (or a compatible version).
3. Add the Verilog files to your Quartus project.
4. Compile the project in Quartus Prime.
5. Program the DE1-SoC board with the resulting bitstream file.
6. Connect a VGA monitor and a PS/2 controller to the board.
7. Enjoy the two-player StickMan Badminton game!

## 🎮 Game Controls

Use the PS/2 controller to:
- Move your stick figure character left and right
- Make your character jump to hit the shuttlecock
- Play against another player in real-time

## 🖥️ Implementation Details

The game is implemented entirely in Verilog HDL, with modules handling:
- Graphics rendering
- Physics simulations for the shuttlecock
- Player control input processing
- Game state management
- Score tracking

## 🙏 Credits and Acknowledgments

- DE1-SoC Board provided by Terasic
- Quartus Prime 18.1 by Intel (formerly Altera)
- VGA adapter created by University of Toronto professor https://www-ug.eecg.utoronto.ca/desl/nios_devices_SoC/dev_vga.html
## 📄 License

Feel free to use or modify these Verilog files for educational or personal projects. If you use this repository as part of your own work, a mention or link back to this project would be greatly appreciated.

Happy Gaming on FPGA!
