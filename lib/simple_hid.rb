require "ffi"
require "simple_hid/version"

module SimpleHID
  extend FFI::Library

  begin
    # Try for common library names across platforms -> the first found will be used
    ffi_lib [
      "hidapi-hidraw",
      "hidapi-libusb",
      "hidapi",
      "libhidapi-hidraw.so.0",
      "libhidapi-hidraw.so"
    ]
  rescue LoadError => e
    raise LoadError, (
      "Could not load the hidapi shared library. " \
      "Original error: #{e.message}"
    )
  end

  enum :hid_bus_type, [
  :unknown,   0x00,
  :usb,       0x01,
  :bluetooth, 0x02,
  :i2c,       0x03,
  :spi,       0x04,
  :virtual,   0x05
]
  # Define the C structure for DeviceInfo
  class DeviceInfo < FFI::Struct 
    layout :path,                :string, 
           :vendor_id,           :ushort, 
           :product_id,          :ushort, 
           :serial_number,       :pointer, 
           :release_number,      :ushort,
           :manufacturer_string, :pointer, 
           :product_string,      :pointer, 
           :usage_page,          :ushort,
           :usage,               :ushort, 
           :interface_number,    :int, 
           :next,                :pointer, 
           :bus_type,            :hid_bus_type
  end

  # Attach the raw C functions from the loaded library 
  attach_function :hid_init, [], :int
  attach_function :hid_exit, [], :void
  attach_function :hid_enumerate, [:ushort, :ushort], :pointer
  attach_function :hid_free_enumeration, [:pointer], :void
  attach_function :hid_open_path, [:string], :pointer
  attach_function :hid_write, [:pointer, :pointer, :size_t], :int
  attach_function :hid_close, [:pointer], :void
  # wchar_t handling 
  attach_function :hid_get_manufacturer_string, [:pointer, :pointer, :size_t], :int
  attach_function :hid_get_product_string,      [:pointer, :pointer, :size_t], :int
  attach_function :hid_get_serial_number_string,[:pointer, :pointer, :size_t], :int

  # Enumeration method 
  def self.enumerate(vid: 0, pid: 0)
    devices = []
    head = hid_enumerate(vid, pid)

    begin
      return [] if head.null?
      current_ptr = head
      until current_ptr.null?
        info_struct = DeviceInfo.new(current_ptr)
        
        # Convert the FFI::Struct to a plain Ruby Hash
        device_info = {
          path: info_struct[:path].dup, 
          vendor_id: info_struct[:vendor_id],
          product_id: info_struct[:product_id],
          release_number: info_struct[:release_number],
          usage_page: info_struct[:usage_page],
          usage: info_struct[:usage],
          interface_number: info_struct[:interface_number],
          bus_type: info_struct[:bus_type]
        }
        devices << device_info
        current_ptr = info_struct[:next]
      end
    ensure
      hid_free_enumeration(head) unless head.null?
    end

    devices
  end

  # Helper method 
  def self.find_path(vid: 0, pid: 0, usage_page: nil, usage: nil)
    all_devices = self.enumerate(vid: vid, pid: pid)
    found_device = all_devices.find do |dev|
      match_usage_page = usage_page.nil? || dev[:usage_page] == usage_page
      match_usage = usage.nil? || dev[:usage] == usage
      match_usage_page && match_usage
    end
    found_device ? found_device[:path] : nil
  end

  class Device

    MAX_STR_LEN = 255 

    def initialize(path)
      @handle = SimpleHID.hid_open_path(path)
      raise "Unable to open HID device at path: #{path}" if @handle.null?
    end

    def write(byte_array)
      raise "Device is closed." if @handle.nil?
      data_string = byte_array.pack('C*')
      data_ptr = FFI::MemoryPointer.from_string(data_string)
      SimpleHID.hid_write(@handle, data_ptr, data_string.bytesize)
    end

    def close
      return if @handle.nil? 
      SimpleHID.hid_close(@handle)
      @handle = nil
    end

    def manufacturer_string
      read_wide_string_with(:hid_get_manufacturer_string)
    end

    def product_string
      read_wide_string_with(:hid_get_product_string)
    end

    def serial_number_string
      read_wide_string_with(:hid_get_serial_number_string)
    end

    private

    def read_wide_string_with(c_function_name)
      raise "Device is closed." if @handle.nil?
      buffer = FFI::MemoryPointer.new(:wchar_t, MAX_STR_LEN)
      result = SimpleHID.send(c_function_name, @handle, buffer, MAX_STR_LEN)
      raise "HIDAPI error while reading string." if result == -1

      return buffer.read_wstring
    end
  end

  self.hid_init
  at_exit { self.hid_exit }
end 