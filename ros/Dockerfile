from ros:noetic-ros-core-focal

RUN groupadd -g 1000 dev && useradd -u 1000 -g 1000 -m dev # TODO: use ARGS instead

RUN apt update && apt install ros-noetic-navigation ros-noetic-ros-control \
      ros-noetic-robot-localization ros-noetic-joy ros-noetic-mavros \
      ros-noetic-mavros-extras ros-noetic-nmea-msgs ros-noetic-ros-controllers \
      ros-noetic-move-base-sequence  ros-noetic-nmea-msgs ros-noetic-teb-local-planner \
      ros-noetic-teleop-twist-joy ros-noetic-twist-mux ros-noetic-smach ros-noetic-xacro \
      build-essential -y

RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh \
      && chmod +x install_geographiclib_datasets.sh && ./install_geographiclib_datasets.sh \
      && rm install_geographiclib_datasets.sh
