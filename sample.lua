-- Define CAN message IDs (replace with actual values from UGVConfigMsg.py)
local MOTION_COMMAND_ID = 0x100 -- Example value, replace with actual ID

-- Vehicle parameters
local WHEELBASE = 1.0 -- Distance between front and rear axles (in meters)
local MAX_STEERING_ANGLE = 30 -- Maximum steering angle in degrees
local PWM_CENTER = 1500 -- PWM signal at neutral (no steering)
local PWM_RANGE = 500 -- PWM range for full steering (1500 ± 500)

-- Function to send a CAN message
function send_can_message(id, data)
    local msg = {
        id = id,
        data = data,
        len = #data
    }
    SRV_Channels:set_output_pwm_chan_timeout(id, data, 1000) -- 1000 ms timeout
end

-- Function to set motion command
function set_motion_command(linear_velocity, angular_velocity)
    local data = {
        linear_velocity & 0xFF,               -- Lower 8 bits of linear_velocity
        (linear_velocity >> 8) & 0xFF,        -- Upper 8 bits of linear_velocity
        angular_velocity & 0xFF,              -- Lower 8 bits of angular_velocity
        (angular_velocity >> 8) & 0xFF        -- Upper 8 bits of angular_velocity
    }
    send_can_message(MOTION_COMMAND_ID, data)
end

-- Function to calculate the steering angle from PWM
function calculate_steering_angle(pwm_value)
    -- Map PWM to steering angle
    local steering_angle = (pwm_value - PWM_CENTER) * MAX_STEERING_ANGLE / PWM_RANGE
    return steering_angle
end

-- Function to calculate Ackermann steering motion
function calculate_ackermann_motion(linear_velocity, steering_angle)
    -- Convert steering angle to radians
    local steering_angle_rad = math.rad(steering_angle)

    -- Calculate angular velocity using Ackermann geometry
    -- angular_velocity = (linear_velocity * tan(steering_angle)) / wheelbase
    local angular_velocity = 0
    if math.abs(steering_angle_rad) > 0 then
        angular_velocity = (linear_velocity * math.tan(steering_angle_rad)) / WHEELBASE
    end
    return angular_velocity
end

-- Main loop
function update()
    -- Read PWM values from channels 1 and 3
    local linear_velocity_pwm = SRV_Channels:get_output_pwm(1) -- Throttle (linear velocity)
    local steering_pwm = SRV_Channels:get_output_pwm(3) -- Steering (angular velocity)

    -- Convert PWM values to desired linear velocity
    -- Assuming linear velocity PWM mapping: PWM of 1500 = 0 m/s, with scaling factor for forward/reverse
    local linear_velocity = (linear_velocity_pwm - PWM_CENTER) * 0.1 -- Example conversion (adjust as needed)

    -- Convert steering PWM to steering angle
    local steering_angle = calculate_steering_angle(steering_pwm)

    -- Calculate angular velocity using Ackermann steering
    local angular_velocity = calculate_ackermann_motion(linear_velocity, steering_angle)

    -- Set motion command with the calculated linear and angular velocities
    set_motion_command(linear_velocity, angular_velocity)
end

-- Register the update function to be called periodically
return update
