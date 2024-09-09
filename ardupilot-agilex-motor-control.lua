-- Define CAN message IDs (replace with actual values from UGVConfigMsg.py)
local MOTION_COMMAND_ID = 0x100 -- Example value, replace with actual ID

-- Function to send a CAN message
function send_can_message(id, data)
    -- Create a CAN message
    local msg = {
        id = id,
        data = data,
        len = #data
    }
    -- Send the CAN message
    SRV_Channels:set_output_pwm_chan_timeout(id, data, 1000) -- 1000 ms timeout
end

-- Function to set motion command
function set_motion_command(linear_velocity, angular_velocity)
    -- Create the data payload for the motion command
    local data = {
        linear_velocity & 0xFF,
        (linear_velocity >> 8) & 0xFF,
        angular_velocity & 0xFF,
        (angular_velocity >> 8) & 0xFF
    }
    -- Send the motion command CAN message
    send_can_message(MOTION_COMMAND_ID, data)
end

-- Example usage: Set linear velocity to 100 and angular velocity to 50
set_motion_command(100, 50)

-- Main loop
function update()
    -- Read PWM values from channels 1 and 3
    local linear_velocity_pwm = SRV_Channels:get_output_pwm(1)
    local angular_velocity_pwm = SRV_Channels:get_output_pwm(3)

    -- Convert PWM values to desired velocity values
    -- Assuming a linear mapping from PWM to velocity
    local linear_velocity = (linear_velocity_pwm - 1500) * 0.1 -- Example conversion
    local angular_velocity = (angular_velocity_pwm - 1500) * 0.1 -- Example conversion

    -- Set motion command with the converted values
    set_motion_command(linear_velocity, angular_velocity)
end

-- Register the update function to be called periodically
return update