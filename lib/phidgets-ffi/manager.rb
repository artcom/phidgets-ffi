module Phidgets
  class Manager
    Klass = Phidgets::FFI::CPhidgetManager
    include Utility

    def initialize(&block)
      if block_given?
        create
        open
        yield self
        close
        delete
      end
    end
    
    def create
      ptr = ::FFI::MemoryPointer.new(:pointer, 1)
      Klass.create(ptr)        
      @handle = ptr.get_pointer(0)
      true
    end

    def open
      Klass.open(@handle)
      # There is no waiting for attachments in the manager, the check is instant so we sleep for a second to give it a chance to register things
      sleep 1
      true
    end
    
    def close
      Klass.close(@handle)
      true
    end

    def delete
      Klass.delete(@handle)
      true
    end

    def devices(timeout=5000)
      devices_ptr, count = ::FFI::MemoryPointer.new(:pointer, 1), ::FFI::MemoryPointer.new(:int)
      Klass.getAttachedDevices(@handle, devices_ptr, count)
      devices = devices_ptr.get_array_of_pointer(0, count.get_int(0))
      device_arr = devices.map do |device|
        device = device.get_pointer(0)
        Common.attributes(device)
      end
      Klass.freeAttachedDevicesArray(devices_ptr)
      
      device_arr
    end

    def server_id
      ptr = ::FFI::MemoryPointer.new(:string)
      Phidgets::FFI::Common.getServerID(@handle, ptr)
      strPtr = ptr.get_pointer(0)
      strPtr.null? ? nil : strPtr.read_string
    end
    
    def server_address
      str_ptr, int_ptr = ::FFI::MemoryPointer.new(:string), ::FFI::MemoryPointer.new(:int)
      Phidgets::FFI::Common.getServerID(@handle, str_ptr, int_ptr)
      strPtr = str_ptr.get_pointer(0)
      address = (strPtr.null? ? nil : strPtr.read_string)
      port = int_ptr.get_int(0)
      [address, port]
    end
    
    def on_attach(obj=nil, &block)
      @on_attach_obj = obj
      @on_attach = Proc.new { |handle, obj_ptr|
        yield object_for(obj_ptr)
      }
      Klass.set_OnAttach_Handler(@handle, @on_attach, pointer_for(obj))
    end

    def on_detach(obj=nil, &block)
      @on_detach_obj = obj
      @on_detach = Proc.new { |handle, obj_ptr|
        yield object_for(obj_ptr)
      }
      Klass.set_OnDetach_Handler(@handle, @on_detach, pointer_for(obj))
    end

    def on_server_connect(obj=nil, &block)
      @on_server_connect_obj = obj
      @on_server_connect = Proc.new { |handle, obj_ptr|
        yield self, object_for(obj_pointer)
      }
      Klass.set_OnServerConnect_Handler(@handle, @on_server_connect, pointer_for(obj))
    end

    def on_server_disconnect(obj=nil, &block)
      @on_server_disconnect_obj = obj
      @on_server_disconnect = Proc.new { |handle, obj_ptr|
        yield self, object_for(obj_ptr)
      }
      Klass.set_OnServerDisconnect_Handler(@handle, @on_server_disconnect, pointer_for(obj))
    end

    def on_error(obj=nil, &block)
      @on_error_obj = obj
      @on_error = Proc.new { |handle, obj_ptr, code, description|
        yield self, object_for(obj_ptr), code, description
      }
      Klass.set_OnError_Handler(@handle, @on_error, pointer_for(obj))
    end
  end
end