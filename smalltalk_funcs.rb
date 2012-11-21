#! /usr/bin/ruby

require 'ostruct'

module SmalltalkFuncs

  def self.included(type)
    type.instance_eval do
      def declare_method(name, first_param, hash_params={}, &block)
        define_method(name, SmalltalkFuncs::method_block(first_param, hash_params, &block))
      end
    end
  end
  
  def self.method_block(first_param, hash_params, &block)
    MethodDeclarationHelper.new(first_param, hash_params, &block).block
  end

  class MethodDeclarationHelper
    attr_reader :block
    
    def initialize(first_param, hash_params={}, &block)
      @params = [first_param] << hash_params.values
      @hash_params = hash_params
      @inner_block = block
      @block = gen_block
    end
  
    private
    
    def gen_block
      inner_block = @inner_block
      eval("
        Proc.new do |#{proc_params}| 
          #{hash_params_locals_initialization};
          _context = OpenStruct.new(#{params_local_hash});
          _context.instance_eval(&inner_block);
        end")
    end
    
    def proc_params
      prc_params = @params[0].to_s
      unless @hash_params.empty?
        prc_params << ", _named_params"
      end
      prc_params
    end
    
    def hash_params_locals_initialization
      locals_initialization = ''
      @hash_params.each_pair do |name, param|
        locals_initialization << "#{param} = _named_params[:#{name}]"
      end
      locals_initialization
    end
    
    def params_local_hash
      @params.map{|param|":#{param} => #{param}"}.join(',')
    end
  end

end

module Kernel
  include SmalltalkFuncs
  
  declare_method :send_a_message, :message, :to => :recipient do
    puts "Dear #{recipient}, #{message}"
  end
end

send_a_message "Hello!", :to => "World"
