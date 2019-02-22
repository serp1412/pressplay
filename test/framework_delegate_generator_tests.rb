require 'minitest/autorun'
require 'pressplay'
require 'xcodeproj'
require 'json'
require_relative '../lib/pressplay/framework_delegate_generator.rb'

class FilesMoverTest < Minitest::Test
	def test_basic_app_delegate

		app_delegate = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

}
"

		result = "import UIKit

public class FrameworkDelegate: UIResponder, UIApplicationDelegate {
}"

		app_delegate_result = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit
import TestAppFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

private let frameworkDelegate = FrameworkDelegate()
}
"
		ast = `sourcekitten structure --text '#{app_delegate}'`

		data = PressPlay::Generator::FrameworkDelegate.new.generate_from(ast, app_delegate, "TestAppFramework")

		assert_equal app_delegate_result, data.app_delegate_raw
		assert_equal result, data.framework_delegate_raw
	end

	def test_app_delegate_and_window_var
		app_delegate = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
}"

app_delegate_result = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit
import TestAppFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

private lazy var frameworkDelegate: FrameworkDelegate = {
        let delegate = FrameworkDelegate()
        delegate.window = self.window

        return delegate
    }()
	var window: UIWindow?
}"

		result = "import UIKit

public class FrameworkDelegate: UIResponder, UIApplicationDelegate {
public var window: UIWindow?
}"
		ast = `sourcekitten structure --text "#{app_delegate}"`

		data = PressPlay::Generator::FrameworkDelegate.new.generate_from(ast, app_delegate, "TestAppFramework")

		puts data.app_delegate_raw
		puts app_delegate_result

		assert_equal app_delegate_result, data.app_delegate_raw
		assert_equal result, data.framework_delegate_raw
	end

	def test_app_delegate_with_window_and_other_vars
		app_delegate = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	@objc let key: String = {
		return .empty
	}()
}"

app_delegate_result = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit
import TestAppFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

private lazy var frameworkDelegate: FrameworkDelegate = {
        let delegate = FrameworkDelegate()
        delegate.window = self.window

        return delegate
    }()
	var window: UIWindow?
}"

		result = "import UIKit

public class FrameworkDelegate: UIResponder, UIApplicationDelegate {
public var window: UIWindow?
@objc public let key: String = {
return .empty
}()
}"
		ast = `sourcekitten structure --text "#{app_delegate}"`

		data = PressPlay::Generator::FrameworkDelegate.new.generate_from(ast, app_delegate, "TestAppFramework")

		puts data.app_delegate_raw
		puts app_delegate_result

		assert_equal app_delegate_result, data.app_delegate_raw
		assert_equal result, data.framework_delegate_raw
	end

	def test_app_delegate_with_window_var_and_an_empty_func
		app_delegate = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	func applicationWillResignActive(_ application: UIApplication) {

}
}"

		app_delegate_result = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit
import TestAppFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

private lazy var frameworkDelegate: FrameworkDelegate = {
        let delegate = FrameworkDelegate()
        delegate.window = self.window

        return delegate
    }()
	var window: UIWindow?
	func applicationWillResignActive(_ application: UIApplication) {

frameworkDelegate.applicationWillResignActive(application)
}
}"

		result = "import UIKit

public class FrameworkDelegate: UIResponder, UIApplicationDelegate {
public var window: UIWindow?
public func applicationWillResignActive(_ application: UIApplication) {

}
}"
		ast = `sourcekitten structure --text '#{app_delegate}'`

		data = PressPlay::Generator::FrameworkDelegate.new.generate_from(ast, app_delegate, "TestAppFramework")

		puts data.framework_delegate_raw
		puts result

		assert_equal app_delegate_result, data.app_delegate_raw
		assert_equal result, data.framework_delegate_raw
	end

	def test_app_delegate_with_window_var_and_a_func
		app_delegate = '//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

var window: UIWindow?
func applicationWillResignActive(_ application: UIApplication) {
// Some comments
let a = "1"
}
}'

app_delegate_result = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit
import TestAppFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

private lazy var frameworkDelegate: FrameworkDelegate = {
        let delegate = FrameworkDelegate()
        delegate.window = self.window

        return delegate
    }()
var window: UIWindow?
func applicationWillResignActive(_ application: UIApplication) {

frameworkDelegate.applicationWillResignActive(application)
}
}"

		result = 'import UIKit

public class FrameworkDelegate: UIResponder, UIApplicationDelegate {
public var window: UIWindow?
public func applicationWillResignActive(_ application: UIApplication) {
// Some comments
let a = "1"
}
}'
		ast = `sourcekitten structure --text '#{app_delegate}'`

		data = PressPlay::Generator::FrameworkDelegate.new.generate_from(ast, app_delegate, "TestAppFramework")

		puts data.app_delegate_raw
		puts app_delegate_result

		assert_equal app_delegate_result, data.app_delegate_raw
		assert_equal result, data.framework_delegate_raw
	end

	def test_app_delegate_with_extra_funcs
		app_delegate = '//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

var window: UIWindow?
func applicationWillResignActive(_ application: UIApplication) {
// Some comments
let a = "1"
}

@objc private func someRandomFunc() {

}

fileprivate func anotherFunc(_ string: String, value: Int) -> Bool {
return true
}
}'

app_delegate_result = "//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit
import TestAppFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

private lazy var frameworkDelegate: FrameworkDelegate = {
        let delegate = FrameworkDelegate()
        delegate.window = self.window

        return delegate
    }()
var window: UIWindow?
func applicationWillResignActive(_ application: UIApplication) {

frameworkDelegate.applicationWillResignActive(application)
}


}"

		result = 'import UIKit

public class FrameworkDelegate: UIResponder, UIApplicationDelegate {
public var window: UIWindow?
public func applicationWillResignActive(_ application: UIApplication) {
// Some comments
let a = "1"
}
@objc private func someRandomFunc() {

}
fileprivate func anotherFunc(_ string: String, value: Int) -> Bool {
return true
}
}'
		ast = `sourcekitten structure --text '#{app_delegate}'`

		data = PressPlay::Generator::FrameworkDelegate.new.generate_from(ast, app_delegate, "TestAppFramework")

		puts data.app_delegate_raw

		assert_equal app_delegate_result, data.app_delegate_raw
		assert_equal result, data.framework_delegate_raw
	end

	def test_default_app_delegate
		app_delegate = '//
//  AppDelegate.swift
//  BasicApp
//
//  Created by Serghei Catraniuc on 2/10/19.
//  Copyright © 2019 TestCompany. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

'

		result = 'import UIKit

public class FrameworkDelegate: UIResponder, UIApplicationDelegate {
public var window: UIWindow?
public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
public func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
public func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
public func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
public func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
public func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}'
		ast = `sourcekitten structure --text '#{app_delegate}'`

		data = PressPlay::Generator::FrameworkDelegate.new.generate_from(ast, app_delegate, "TestAppFramework")

		puts data.app_delegate_raw
		
		assert_equal app_delegate, data.app_delegate_raw
		assert_equal result, data.framework_delegate_raw
	end
end



