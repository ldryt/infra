{ pkgs, ... }:
{
  # --- Display
  #
  # Problem: when both camera and display are connected, the display doesn't function (but the camera does) and the system logs are flooded with this error:
  #   i2c-bcm2835 fe205000.i2c: i2c transfer timed out
  #   Goodix-TS 10-0014: Error writing 1 bytes to 0x814e: -110
  #   Goodix-TS 10-0014: Error reading 10 bytes from 0x814e: -110
  #
  # Potential fix: https://forums.raspberrypi.com/viewtopic.php?t=381277

  # Add this to config.txt:
  #   dtoverlay=vc4-kms-v3d-pi4,cma-128
  #   dtoverlay=vc4-kms-dsi-waveshare-panel,2_8_inch

  hardware.deviceTree.overlays = [
    {
      # More info: https://github.com/raspberrypi/firmware/blob/0ea28740607daed588912930379ed6ad40cfc4be/boot/overlays/README#L5594
      # dts with modified compatibility from: https://github.com/raspberrypi/linux/blob/bba53a117a4a5c29da892962332ff1605990e17a/arch/arm/boot/dts/overlays/vc4-kms-dsi-waveshare-panel-overlay.dts
      name = "vc4-kms-dsi-waveshare-panel";
      dtsText = ''
        /*
         * Device Tree overlay for Waveshare DSI Touchscreens
         *
         */

        /dts-v1/;
        /plugin/;

        / {
        	compatible = "brcm,bcm2711";

        	dsi_frag: fragment@0 {
        		target = <&dsi1>;
        		__overlay__ {
        			#address-cells = <1>;
        			#size-cells = <0>;
        			status = "okay";
        			port {
        				dsi_out: endpoint {
        					remote-endpoint = <&panel_in>;
        				};
        			};
        		};
        	};

        	fragment@1 {
        		target-path = "/";
        		__overlay__ {
        		};
        	};

        	i2c_frag: fragment@2 {
        		target = <&i2c_csi_dsi>;
        		__overlay__ {
        			#address-cells = <1>;
        			#size-cells = <0>;
        			status = "okay";

        			panel: panel_disp1@45 {
        				reg = <0x45>;
        				compatible = "waveshare,10.1inch-panel";

        				port {
        					panel_in: endpoint {
        						remote-endpoint = <&dsi_out>;
        					};
        				};
        			};

        			touch: goodix@14 {
        				reg = <0x14>;
        				compatible = "goodix,gt911";
        			};

        			touch2: ilitek@41 {
        				compatible = "ilitek,ili251x";
        				reg = <0x41>;
        				status = "disabled";
        			};
        		};
        	};

        	fragment@3 {
        		target = <&i2c0if>;
        		__overlay__ {
        			status = "okay";
        		};
        	};

        	fragment@4 {
        		target = <&i2c0mux>;
        		__overlay__ {
        			status = "okay";
        		};
        	};

        	fragment@5 {
        		target = <&i2c_arm>;
        		__dormant__ {
        			status = "okay";
        		};
        	};

        	__overrides__ {
        		2_8_inch = <&panel>, "compatible=waveshare,2.8inch-panel",
        				   <&touch>, "touchscreen-size-x:0=480",
        				   <&touch>, "touchscreen-size-y:0=640",
        				   <&touch>, "touchscreen-inverted-y?",
        				   <&touch>, "touchscreen-swapped-x-y?";
        		3_4_inch = <&panel>, "compatible=waveshare,3.4inch-panel",
        				   <&touch>, "touchscreen-size-x:0=800",
        				   <&touch>, "touchscreen-size-y:0=800";
        		4_0_inch = <&panel>, "compatible=waveshare,4.0inch-panel",
        				   <&touch>, "touchscreen-size-x:0=800",
        				   <&touch>, "touchscreen-size-y:0=480",
        				   <&touch>, "touchscreen-inverted-x?",
        				   <&touch>, "touchscreen-swapped-x-y?";
        		7_0_inchC = <&panel>, "compatible=waveshare,7.0inch-c-panel",
        				   <&touch>, "touchscreen-size-x:0=800",
        				   <&touch>, "touchscreen-size-y:0=480";
        		7_9_inch = <&panel>, "compatible=waveshare,7.9inch-panel",
        				   <&touch>, "touchscreen-size-x:0=4096",
        				   <&touch>, "touchscreen-size-y:0=4096",
        				   <&touch>, "touchscreen-inverted-x?",
        				   <&touch>, "touchscreen-swapped-x-y?";
        		8_0_inch = <&panel>, "compatible=waveshare,8.0inch-panel",
        				   <&touch>, "touchscreen-size-x:0=800",
        				   <&touch>, "touchscreen-size-y:0=1280",
        				   <&touch>, "touchscreen-inverted-x?",
        				   <&touch>, "touchscreen-swapped-x-y?";
        		10_1_inch = <&panel>, "compatible=waveshare,10.1inch-panel",
        				   <&touch>, "touchscreen-size-x:0=800",
        				   <&touch>, "touchscreen-size-y:0=1280",
        				   <&touch>, "touchscreen-inverted-x?",
        				   <&touch>, "touchscreen-swapped-x-y?";
        		11_9_inch = <&panel>, "compatible=waveshare,11.9inch-panel",
        				   <&touch>, "touchscreen-inverted-x?",
        				   <&touch>, "touchscreen-swapped-x-y?";
        		4_0_inchC = <&panel>, "compatible=waveshare,4inch-panel",
        				   <&touch>, "touchscreen-size-x:0=720",
        				   <&touch>, "touchscreen-size-y:0=720";
        		5_0_inch = <&panel>, "compatible=waveshare,5.0inch-panel",
        				   <&touch>, "touchscreen-inverted-x?",
        				   <&touch>, "touchscreen-inverted-y?";
        		6_25_inch = <&panel>, "compatible=waveshare,6.25inch-panel",
        				   <&touch>, "touchscreen-inverted-x?",
        				   <&touch>, "touchscreen-inverted-y?";
        		8_8_inch = <&panel>, "compatible=waveshare,8.8inch-panel";
        		13_3_inch_4lane = <&panel>, "compatible=waveshare,13.3inch-4lane-panel",
        				  <&touch2>, "status=okay";
        		13_3_inch_2lane = <&panel>, "compatible=waveshare,13.3inch-2lane-panel",
        				  <&touch2>, "status=okay";
        		i2c1 = <&i2c_frag>, "target:0=",<&i2c1>,
        		       <0>, "-3-4+5";
        		disable_touch = <&touch>, "status=disabled";
        		rotation = <&panel>, "rotation:0";
        		invx = <&touch>,"touchscreen-inverted-x?";
        		invy = <&touch>,"touchscreen-inverted-y?";
        		swapxy = <&touch>,"touchscreen-swapped-x-y?";
        		dsi0 = <&dsi_frag>, "target:0=",<&dsi0>,
        		       <&i2c_frag>, "target:0=",<&i2c_csi_dsi0>;
        	};
        };
      '';
    }
    {
      # More info: https://github.com/raspberrypi/firmware/blob/0ea28740607daed588912930379ed6ad40cfc4be/boot/overlays/README#L5679
      name = "vc4-kms-v3d-pi4";
      dtboFile = pkgs.fetchurl {
        url = "https://github.com/raspberrypi/firmware/raw/0ea28740607daed588912930379ed6ad40cfc4be/boot/overlays/vc4-kms-v3d-pi4.dtbo";
        hash = "sha256-FV7AcfJqjUXEUk7gDFA3rXzrjMgdIhZAudnXF3xBbd8=";
      };
    }
  ];
}
