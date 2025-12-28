# UVM_DPI_MATLAB_CRC5
Interaction between Reference Model of UVM Environment and MATLAB in Linux System




In digital circuit design verification, Matlab is often used as algorithm reference model to verify the correctness of RTL design. Because the project needs to use matlab, it is not suitable to convert matlab to c language in a short time. In this paper,.m file is compiled into.so library, and it is called in UVM environment through SystemVerilog DPI.

This article will record the flow of the experiment, RTL used here is a verification module about crc5 that I wrote on the set creation competition, the main purpose of this article is to explore how to call "Matlab" as a reference model, RTL internal details will not be explained too much, this UVM environment only involves "reference model", for random, coverage will not be discussed too much


