Dropping JSP means the image no longer needs joint_state_publisher_gui, so the runtime stage gets smaller. There's one side effect covered after the build steps.

1. Project layout(host)
~/walker-viz/
├── Dockerfile
├── fastdds.xml
├── relay.py
└── msgs/    

2. Dockerfile
The dockerfile has been rebuilt to cover the shift in operating systems.

3. Build
```bash
cd ~/walker-viz
docker build -t walker-viz:vf .
```
Add sudo if your user isn't in the docker group.

4. Verify the image
```bash
docker run --rm walker-viz:vf bash -lc "ros2 interface show bodyctrl_msgs/msg/MotorStatusMsg && ls /ros2_ws/src/Tienkung_URDF/tiangong2pro_urdf/urdf/"
```
You should see the message definition and tiangong2.0_pro_with_hands.urdf.

5. Updated pipeline: Three terminals instead of four.
Start the container with the following message.
```bash
docker run -it --name tg2-rviz --net=host \
  -e DISPLAY=$DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -e ROS_DOMAIN_ID=0 \
  -e RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
  -e FASTRTPS_DEFAULT_PROFILES_FILE=/root/fastdds.xml \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $HOME/walker-viz/fastdds.xml:/root/fastdds.xml \
  --device /dev/dri \
  walker-viz:vf bash
```
Open each shell with the following 
```bash
docker exec -it tg2-rviz bash.

#First terminal
python3 /root/relay.py

#Second terminal
ros2 run robot_state_publisher robot_state_publisher --ros-args \
  -p robot_description:="$(cat /ros2_ws/src/Tienkung_URDF/tiangong2pro_urdf/urdf/tiangong2.0_pro_with_hands.urdf)" \
  -r joint_states:=tg2_joints

#Third terminal
rviz2
```

6. The data flow 
robot --DDS--> relay.py --/tg2_joints--> robot_state_publisher --/tf/-->RViz2

7. Side effect of removing JSP
JSP also published a default value of 0 for every joint nobody else was publishing. relay.py only covers the motors the robot reports so the finger joints (about 24 of the 54 non-fixed joints) will have no transform.
RViz will show "No transform from [finger link] to [pelvis].
The fix is a work around python file that publishes 0 for each finger joint. This will be ran 
on its own terminal so another shell has to be sourced and ran.