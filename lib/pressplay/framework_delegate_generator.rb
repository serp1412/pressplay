module PressPlay
	module Generator
		class FrameworkDelegate
			require 'json'

			def generateFrom(app_delegate_ast, app_delegate_raw_string)
				import_lines = app_delegate_raw_string.lines.select { |l| l.start_with? "import" }
				frameworkDelegateRaw = ""
				import_lines.each { |l| frameworkDelegateRaw << l + "\n" }
				frameworkDelegateRaw << "public class FrameworkDelegate: "
				json = JSON.parse(app_delegate_ast)
				# TODO: assuming that first key.substructure is always the AppDelegate class is bad idea. Instead should looke for it
				app_delegate_structure = json['key.substructure'].first
				inheritence = app_delegate_structure['key.inheritedtypes']
				frameworkDelegateRaw << inheritence.map { |d| d['key.name'] }.join(', ')
				frameworkDelegateRaw << ' {'
				frameworkDelegateRaw << "\n"

				app_delegate_structure['key.substructure']&.each do |sub_struct|
					frameworkDelegateRaw << (sub_struct['key.accessibility'] == 'source.lang.swift.accessibility.internal' ? 'public' : 'private')
					frameworkDelegateRaw << ' '
					
					frameworkDelegateRaw << (sub_struct['key.kind'].is_var? ? 
						string_from_var(sub_struct) : 
						string_from_func(sub_struct, app_delegate_raw_string))
					frameworkDelegateRaw << ((frameworkDelegateRaw.end_with? "\n") ? "" : "\n")
				end

				frameworkDelegateRaw << '}'

				FrameworkDelegateData.new(frameworkDelegateRaw, app_delegate_raw_string)
			end

			private

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
			attr_reader :frameworkDelegateRaw
			attr_reader :appDelegateRaw

			def initialize(frameworkDelegateRaw, appDelegateRaw)
				@frameworkDelegateRaw = frameworkDelegateRaw
				@appDelegateRaw = appDelegateRaw
			end
		end
	end
end

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