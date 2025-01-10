# StickManBadminton-on-FPGA
A Two-Player Interactive Game on FPGA
The detailed description slides can be found in the links provided below:
https://docs.google.com/presentation/d/1zoz6aC_Ih6Uw6YF6MzBEiaykrYxHg3aTIHqkL9wZQng/edit?usp=sharing

A Two-Player Interactive Game on an FPGA

This repository contains the Verilog (.v) files necessary to implement a two-player badminton game on an FPGA. For a detailed overview of the project, including design concepts, implementation details, and demonstrations, please refer to the presentation slides:

https://docs.google.com/presentation/d/1zoz6aC_Ih6Uw6YF6MzBEiaykrYxHg3aTIHqkL9wZQng/edit?usp=sharing

Overview
Development Environment: Quartus Prime 18.1
FPGA Board: DE1-SoC
Display: VGA Monitor
User Input: PS/2 Controller
StickManBadminton-on-FPGA is designed as a two-player game that runs on the DE1-SoC board. After compiling the Verilog files in Quartus Prime 18.1, the bitstream is uploaded to the FPGA board, which then drives a VGA monitor to display the game. Players use a PS/2 controller to move the on-screen stickman characters and play badminton against each other.

Repository Contents
Verilog Source Files (.v):
All the necessary Verilog modules for the game’s logic, rendering, and input handling.
Note: This repository does not include configuration files for Quartus or other project-related files. You can create your own Quartus project and add these .v files as source modules.

Getting Started
Clone this repository or download the .v files.
Create a new project in Quartus Prime 18.1 (or a compatible version).
Add the Verilog files to your Quartus project.
Compile the project in Quartus Prime.
Program the DE1-SoC board with the resulting bitstream file.
Connect a VGA monitor and a PS/2 controller to the board.
Enjoy the two-player StickMan Badminton game!
Credits and Acknowledgments
DE1-SoC Board provided by Terasic.
Quartus Prime 18.1 by Intel (formerly Altera).
License
Feel free to use or modify these Verilog files for educational or personal projects. If you use this repository as part of your own work, a mention or link back to this project would be greatly appreciated.

Happy Gaming on FPGA!