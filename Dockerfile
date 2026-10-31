FROM ros:humble-ros-core AS BUILD 
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential \
    python3-colcon-common-extensions python3-rosdep \
    ros-humble-xacro ros-humble-rmw-fastrtps-cpp \
 && rm -rf /var/lib/apt/lists/*

RUN (rosdep init || true) && rosdep update --rosdistro humble

WORKDIR /ros2_ws/src
RUN git clone https://github.com/Open-X-Humanoid/Tienkung_URDF.git
COPY msgs/ /ros2_ws/src/msgs/

WORKDIR /ros2_ws
RUN rosdep install --from-paths src --ignore-src -r -y
RUN . /opt/ros/humble/setup.sh && \
    colcon build --packages-select bodyctrl_msgs tiangong2pro_urdf


# ------------ Runtime stage ------------
FROM ros:humble-ros-core 
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-rviz2 ros-humble-robot-state-publisher \
    ros-humble-xacro ros-humble-rmw-fastrtps-cpp \
    mesa-utils \
 && rm -rf /var/lib/apt/lists/*


COPY --from=build /ros2_ws /ros2_ws
COPY fastdds.xml /root/fastdds.xml
COPY relay.py /root/relay.py

ENV FASTRTPS_DEFAULT_PROFILES_FILE=/root/fastdds.xml \
    RMW_FASTRTPS_USE_SHM=0 \
    RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
    ROS_DOMAIN_ID=0

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "source /ros2_ws/install/setup.bash" >> /root/.bashrc

WORKDIR /root
CMD ["bash"]