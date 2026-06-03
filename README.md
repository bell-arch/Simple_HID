# SimpleHID: A Python-Inspired HIDAPI Wrapper for Ruby

This project is a minimal FFI-based Ruby wrapper for the `hidapi` library. It was created to provide a simple interface HID communication, closely mirroring the design and ease of use of the Python `pyhidapi` library.

## Motivation

While other HID libraries for Ruby exist, I found they lacked certain features for advanced device discovery. In particular, the ability to filter devices by `usage_page` and `usage` was not readily available. This functionality is critical for precisely identifying a specific device interface when a single piece of hardware exposes multiple HID interfaces.

## Features & Current Status

The implementation in its current form, is intentionally lightweight and purpose-built. It provides functionality for:

*   **Advanced Device Discovery:** Find devices by VID, PID, `usage_page`, and `usage`.
*   **Write-Only Operations:** Send command packets to any connected HID device.

It is perfectly suited for projects involving custom peripheral control, especially those that require reverse-engineering a device's USB protocol. The library handles the low-level device connection, allowing you to focus on crafting and sending the correct byte commands.

## Installation

- Ensure the system `hidapi` library is installed:
  - Arch: `sudo pacman -S hidapi`
  - Debian/Ubuntu: `sudo apt install libhidapi-hidraw0`
  - macOS (Homebrew): `brew install hidapi`
- Install the Ruby gem: `gem install simple_hid`

## Usage

First, require the library in your script:

```ruby
require 'simple_hid'
```

### 1. Finding a Specific Device

The primary feature of the library is finding a device by its specific attributes. The `find_path` method will return the system path as a string if a device is found, or `nil` if not.

```ruby
# Define the attributes of the device you're looking for
VENDOR_ID = 0x0CF2
PRODUCT_ID = 0xA102
USAGE_PAGE = 0xFF72
USAGE = 0x00A1

# Search for the device path
path = SimpleHID.find_path(
  vid: VENDOR_ID,
  pid: PRODUCT_ID,
  usage_page: USAGE_PAGE,
  usage: USAGE
)

unless path
  puts "Error: Device not found."
  exit
end

puts "Found device at: #{path}"
```

### 2. Listing All Connected HID Devices

You can also enumerate all HID devices connected to the system, which is useful for discovery. The `enumerate` method returns an array of hashes, with each hash representing one device.

```ruby
# Get a list of all HID devices
all_devices = SimpleHID.enumerate

# Print the details for each device found
all_devices.each do |device_info|
  puts "Path: #{device_info[:path]}"
  puts "  Vendor ID:  0x#{device_info[:vendor_id].to_s(16)}"
  puts "  Product ID: 0x#{device_info[:product_id].to_s(16)}"
  puts "  Usage Page: 0x#{device_info[:usage_page].to_s(16)}"
  puts "-" * 20
end
```

### 3. Opening a Device and Writing Data

Once you have the device path, you can open it, send commands, and ensure it's closed safely using a `begin...ensure` block.

```ruby
# (Continuing from the 'find_path' example above...)

begin
  # 1. Open the device using its path
  device = SimpleHID::Device.new(path)
  puts "Device opened successfully."

  # 2. Prepare your command as an array of bytes
  # This command must match the protocol of your specific device.
  # Note: The underlying HID report may require padding to a specific length.
  # This library sends exactly what you provide.
  command = [0xE0, 0x10, 0x60, 0x01, 0x03, 0x00, 0x00, 0x00]

  # 3. Write the command to the device
  device.write(command)
  puts "Command sent."

ensure
  # 4. The 'ensure' block guarantees the device is closed,
  # even if an error occurs during the write operation.
  if device
    device.close
    puts "Device closed cleanly."
  end
end
```
```