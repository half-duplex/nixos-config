{flake, ...}: {
  imports = with flake.modules.nixos; [
    frigate
  ];

  mal.services.frigate = {
    enable = true;
    hostname = "panopticon.sec.gd";
    secrets = ["cam_task_pw" "cam_workshop_pw" "cam_wyze_pw"];
    useUSBCoral = true;
    settings = {
      mqtt = {
        host = "[::1]";
        user = "frigate";
        password = "{FRIGATE_MQTT_PASSWORD}";
      };
      face_recognition = {
        enabled = true;
        #model_size = "large";
      };
      motion.enabled = true;
      record = {
        # frigate 0.17
        #continuous.days = 1;
        #motion.days = 15;
        retain = {
          days = 5;
          mode = "all";
        };
        detections.retain = {
          days = 15;
          mode = "motion";
        };
      };
      cameras = {
        task = {
          enabled = true;
          detect.enabled = false;
          record.enabled = true;
          live.streams = {
            "High Quality" = "task_hd";
            "Low Quality" = "task";
          };
          #onvif = {
          #  host = "10.0.65.182";
          #  port = 80;
          #  user = "thingino";
          #  password = "{FRIGATE_CAM_TASK_PW}";
          #};
          ffmpeg.inputs = [
            {
              path = "rtsp://stream:{FRIGATE_GO2RTC_PASSWORD}@[::1]:8554/task?timeout=30";
              roles = ["detect"];
            }
            {
              path = "rtsp://stream:{FRIGATE_GO2RTC_PASSWORD}@[::1]:8554/task_hd?timeout=30";
              roles = ["record"];
            }
          ];
        };
        workshop = {
          enabled = true;
          detect.enabled = false;
          record.enabled = true;
          live.streams = {
            "High Quality" = "workshop_hd";
            "Low Quality" = "workshop";
          };
          #onvif = {
          #  host = "10.0.65.181";
          #  port = 80;
          #  user = "thingino";
          #  password = "{FRIGATE_CAM_WORKSHOP_PW}";
          #};
          ffmpeg.inputs = [
            {
              path = "rtsp://stream:{FRIGATE_GO2RTC_PASSWORD}@[::1]:8554/workshop?timeout=30";
              roles = ["detect"];
            }
            {
              path = "rtsp://stream:{FRIGATE_GO2RTC_PASSWORD}@[::1]:8554/workshop_hd?timeout=30";
              roles = ["record"];
            }
          ];
        };
        wyze = {
          enabled = true;
          detect.enabled = true;
          record.enabled = true;
          live.streams = {
            "High Quality" = "wyze_hd";
            "Low Quality" = "wyze";
          };
          #onvif = {
          #  host = "10.0.65.180";
          #  port = 80;
          #  user = "thingino";
          #  password = "{FRIGATE_CAM_WYZE_PW}";
          #};
          ffmpeg.inputs = [
            {
              path = "rtsp://stream:{FRIGATE_GO2RTC_PASSWORD}@[::1]:8554/wyze?timeout=30";
              roles = ["detect"];
            }
            {
              path = "rtsp://stream:{FRIGATE_GO2RTC_PASSWORD}@[::1]:8554/wyze_hd?timeout=30";
              roles = ["record"];
            }
          ];
        };
      };
      go2rtc.streams = {
        task = "rtsp://thingino:\${cam_task_pw}@10.0.65.182/sd#timeout=30&backchannel=0";
        task_hd = "rtsp://thingino:\${cam_task_pw}@10.0.65.182/hd#timeout=30&backchannel=0";
        workshop = "rtsp://thingino:\${cam_workshop_pw}@10.0.65.181/sd#timeout=30&backchannel=0";
        workshop_hd = "rtsp://thingino:\${cam_workshop_pw}@10.0.65.181/hd#timeout=30&backchannel=0";
        wyze = "rtsp://thingino:\${cam_wyze_pw}@10.0.65.180/sd#timeout=30&backchannel=0";
        wyze_hd = "rtsp://thingino:\${cam_wyze_pw}@10.0.65.180/hd#timeout=30&backchannel=0";
      };
    };
  };
}
