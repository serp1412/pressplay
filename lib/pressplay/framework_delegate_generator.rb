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
					@framework_delegate_raw << (sub_struct['key.accessibility'] == 'source.lang.swift.accessibility.internal' ? 'public' : 'private')
					@framework_delegate_raw << ' '
					
					@framework_delegate_raw << (sub_struct['key.kind'].is_var? ? 
						string_from_var(sub_struct) :
						string_from_func(sub_struct, @app_delegate_raw_string))
					@framework_delegate_raw << ((@framework_delegate_raw.end_with? "\n") ? "" : "\n")
				end

				@framework_delegate_raw << '}'
			end

			def edit_app_delegate
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

				beginning_of_body = @app_delegate_structure['key.bodyoffset'] - 1
				@app_delegate_raw_string.insert(beginning_of_body, "\n" + framework_delegate_var)

				insertion_point = @import_lines.last.length + @app_delegate_raw_string.index(@import_lines.last)
				@app_delegate_raw_string.insert(insertion_point, "import #{@framework_name}\n")
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

	def is_var?
		self == 'source.lang.swift.decl.var.instance' || self == 'source.lang.swift.decl.let.instance'
	end
end