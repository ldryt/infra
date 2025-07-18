{ ... }:
{
  hardware.deviceTree.overlays = [
    {
      # More info: https://github.com/raspberrypi/firmware/blob/0ea28740607daed588912930379ed6ad40cfc4be/boot/overlays/README#L1142
      # dts with modified compatibility from: https://github.com/raspberrypi/linux/blob/bba53a117a4a5c29da892962332ff1605990e17a/arch/arm/boot/dts/overlays/vc4-kms-dsi-waveshare-panel-overlay.dts
      name = "miniuart-bt";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        /* Switch Pi3 Bluetooth function to use the mini-UART (ttyS0) and restore
           UART0/ttyAMA0 over GPIOs 14 & 15. Note that this may reduce the maximum
           usable baudrate.

           It is also necessary to edit /lib/systemd/system/hciuart.service and
           replace ttyAMA0 with ttyS0, unless you have a system with udev rules
           that create /dev/serial0 and /dev/serial1, in which case use /dev/serial1
           instead because it will always be correct.

           If cmdline.txt uses the alias serial0 to refer to the user-accessable port
           then the firmware will replace with the appropriate port whether or not
           this overlay is used.
        */

        #include <dt-bindings/gpio/gpio.h>

        /{
        	compatible = "brcm,bcm2711";

        	fragment@0 {
        		target = <&uart0>;
        		__overlay__ {
        			pinctrl-names = "default";
        			pinctrl-0 = <&uart0_pins>;
        			status = "okay";
        		};
        	};

        	fragment@1 {
        		target = <&bt>;
        		__overlay__ {
        			status = "disabled";
        		};
        	};

        	fragment@2 {
        		target = <&uart1>;
        		__overlay__ {
        			pinctrl-names = "default";
        			pinctrl-0 = <&uart1_pins>;
        			status = "okay";
        		};
        	};

        	fragment@3 {
        		target = <&uart0_pins>;
        		__overlay__ {
        			brcm,pins;
        			brcm,function;
        			brcm,pull;
        		};
        	};

        	fragment@4 {
        		target = <&uart1>;
        		__overlay__ {
        			pinctrl-0 = <&uart1_bt_pins>;
        		};
        	};

        	fragment@5 {
        		target-path = "/aliases";
        		__overlay__ {
        			serial0 = "/soc/serial@7e201000";
        			serial1 = "/soc/serial@7e215040";
        			bluetooth = "/soc/serial@7e215040/bluetooth";
        		};
        	};

        	fragment@6 {
        		target = <&minibt>;
        		minibt_frag: __overlay__ {
        			status = "okay";
        		};
        	};

        	__overrides__ {
        		krnbt = <&minibt_frag>,"status";
        	};
        };
      '';
    }
  ];
}
