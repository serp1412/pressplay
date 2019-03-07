module PressPlay
	module Generator
		class FrameworkDelegate
			require 'json'

			def generate_from(app_delegate_ast, app_delegate_raw_string, framework_name)
				@app_delegate_raw_string = app_delegate_raw_string
				@app_delegate_ast = app_delegate_ast
				@framework_name = framework_name
				@import_lines = @app_delegate_raw_string.lines.select { |l| l.start_with? "import" }

				create_framework_delegate()
				edit_app_delegate()

				FrameworkDelegateData.new(@framework_delegate_raw, @app_delegate_raw_string)
			end

			private

			def create_framework_delegate
				@framework_delegate_raw = ""
				@import_lines.each { |l| @framework_delegate_raw << l + "\n" }
				@framework_delegate_raw << "public class FrameworkDelegate: "
				json = JSON.parse(@app_delegate_ast)
				# TODO: assuming that first key.substructure is always the AppDelegate class is bad idea. Instead should look for it
				@app_delegate_structure = json['key.substructure'].first
				inheritence = @app_delegate_structure['key.inheritedtypes']
				@framework_delegate_raw << inheritence.map { |d| d['key.name'] }.join(', ')
				@framework_delegate_raw << ' {'
				@framework_delegate_raw << "\n"

				@app_delegate_structure['key.substructure']&.each do |sub_struct|
					@framework_delegate_raw << prefix_attributes_for(sub_struct) #(sub_struct['key.accessibility'] == 'source.lang.swift.accessibility.internal' ? 'public' : 'private')
					@framework_delegate_raw << ' '
					
					@framework_delegate_raw << (sub_struct['key.kind'].is_var? ? 
						string_from_var(sub_struct) :
						string_from_func(sub_struct, @app_delegate_raw_string))
					@framework_delegate_raw << ((@framework_delegate_raw.end_with? "\n") ? "" : "\n")
				end

				@framework_delegate_raw << '}'
			end

			def prefix_attributes_for(sub_struct)
				return "" if sub_struct['key.attributes'].nil? && sub_struct['key.accessibility'].nil?
				return sub_struct['key.accessibility'].to_access_level if sub_struct['key.attributes'].nil?
				beginning_of_func = beginning_of_func(sub_struct)
				beginning_of_func_name = sub_struct['key.offset'] - 3
				@app_delegate_raw_string[beginning_of_func..beginning_of_func_name]
			end

			def edit_app_delegate
				@app_delegate_structure['key.substructure']&.reverse&.each do |sub_struct|
					if sub_struct['key.kind'].is_func?
						process_app_delegate_func(sub_struct)
					else
						process_app_delegate_var(sub_struct)
					end
				end

				add_framework_delegate_property
				add_import_framework_line
			end

			def process_app_delegate_var(sub_struct)
				return if sub_struct['key.name'] == 'window'
				remove_additional_func(sub_struct)
			end

			def process_app_delegate_func(sub_struct)
				if sub_struct['key.name'].include? "application"
					adjust_app_delegate_func(sub_struct)
				else
					remove_additional_func(sub_struct)
				end
			end

			def remove_additional_func(sub_struct)
				beginning_of_func = beginning_of_func(sub_struct)
				length_of_func = length_of_func(sub_struct, beginning_of_func)
				@app_delegate_raw_string[beginning_of_func..beginning_of_func+length_of_func] = ""
			end

			def beginning_of_func(sub_struct)
				return sub_struct['key.offset'] - 1 if sub_struct['key.attributes'].nil?
				sorted = sub_struct['key.attributes'].sort_by { |a| a['key.offset'] }
				sorted.first['key.offset'] - 1
			end

			def length_of_func(sub_struct, beginning_of_func)
				adjustment_for_attributes = (sub_struct['key.offset'] - 1) - beginning_of_func
				sub_struct['key.length'] + adjustment_for_attributes
			end

			def add_import_framework_line
				insertion_point = @import_lines.last.length + @app_delegate_raw_string.index(@import_lines.last)
				@app_delegate_raw_string.insert(insertion_point, "import #{@framework_name}\n")
			end

			def add_framework_delegate_property
				framework_delegate_var = ""

				if @framework_delegate_raw.include? "var window: UIWindow?"

					framework_delegate_var = "private lazy var frameworkDelegate: FrameworkDelegate = {
        let delegate = FrameworkDelegate()
        delegate.window = self.window

        return delegate
    }()"
  			else
  				framework_delegate_var = "private let frameworkDelegate = FrameworkDelegate()"
				end

				beginning_of_body = @app_delegate_structure['key.bodyoffset']
				@app_delegate_raw_string.insert(beginning_of_body, "\n" + framework_delegate_var)
			end

			def adjust_app_delegate_func(sub_struct)
				beginning_of_body = sub_struct['key.bodyoffset']
				body_length = sub_struct['key.bodylength']
				@app_delegate_raw_string[beginning_of_body..(beginning_of_body + body_length - 2)] = ""

				func = ""
				func << "return " unless sub_struct['key.typename'].nil?
				func << "frameworkDelegate."
				func_name = sub_struct['key.name']
				arg_sub_structs = sub_struct['key.substructure']&.select { |ss| ss['key.kind'].is_param? }

				add_args_to_func(func_name, arg_sub_structs) unless arg_sub_structs.nil?

				func << func_name

				@app_delegate_raw_string.insert(sub_struct['key.bodyoffset'], "\n" + func + "\n")
			end

			def add_args_to_func(func_name, arg_sub_structs)
				arg_indices = func_name.all_indices_of(":").reverse
				first_pass = true
				arg_struct = arg_sub_structs.reverse
				arg_struct.each_index do |index|
					ss = arg_struct[index]
					name = ss['key.name']
					colon_index = arg_indices[index]
					need_to_replace = func_name.is_previous_character?("_", colon_index)
					name_to_insert = first_pass ? name : name + ", "
					if need_to_replace
						func_name[colon_index - 1..colon_index] = name_to_insert
					else
						func_name.insert(colon_index + 1, name_to_insert)
					end

					first_pass = false
				end
			end

			# TODO: verify if I can use the string_from_func instead of this for vars and lets
			def string_from_var(substructure)
				result = ""
				result << substructure['key.kind'].to_kind
				result << ' '
				result << substructure['key.name'] + ": "
				result << substructure['key.typename']
			end

			def string_from_func(substructure, raw_string)
				offset = substructure['key.offset'] - 1
				body_offset = substructure['key.bodyoffset']
				body_length = substructure['key.bodylength']
				raw_string[offset..body_offset+body_length]
			end
		end

		class FrameworkDelegateData
			attr_reader :framework_delegate_raw
			attr_reader :app_delegate_raw

			def initialize(framework_delegate_raw, app_delegate_raw)
				@framework_delegate_raw = framework_delegate_raw
				@app_delegate_raw = app_delegate_raw
			end
		end
	end
end

private

class String
	def to_kind
			return 'var' if self == 'source.lang.swift.decl.var.instance'
			return 'let' if self == 'source.lang.swift.decl.let.instance'
			return 'func' if self == 'source.lang.swift.decl.function.method.instance'
			# TODO: add parsing for static kinds
	end

	def to_access_level
		return 'public' if self == 'source.lang.swift.accessibility.internal'
		return 'private' if self == 'source.lang.swift.accessibility.private'
		return 'fileprivate' if self == 'source.lang.swift.accessibility.fileprivate'
	end

	def is_var?
		self == 'source.lang.swift.decl.var.instance' || self == 'source.lang.swift.decl.let.instance'
	end

	def is_func?
		!is_var?
	end

	def is_param?
		self == "source.lang.swift.decl.var.parameter"
	end

	def all_indices_of(char)
		return (0 ... length).find_all { |i| self[i,1] == char }
	end

	def is_previous_character?(char, at_index)
		return false if self.empty?
		return false if at_index == 0

		self[at_index - 1] == char
	end
end