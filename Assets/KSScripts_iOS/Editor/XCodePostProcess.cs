
#if UNITY_IOS

using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode; //XcodeAPI
using System.Collections;
using System.IO;
using System.Text.RegularExpressions;

public static class XCodePostProcess
{
	[PostProcessBuild]
	public static void OnPostprocessBuild(BuildTarget buildTarget, string path)
	{
		if (buildTarget != BuildTarget.iOS) {
			Debug.LogWarning ("Target is not IOS. XCodePostProcess will not run");
			return;
		}

		// Create a new project object from build target
		string projPath = PBXProject.GetPBXProjectPath(path);
		PBXProject project = new PBXProject();
		project.ReadFromString(File.ReadAllText(projPath));
		string target = project.TargetGuidByName("Unity-iPhone");

		project.AddFrameworkToProject(target, "libstdc++.6.0.9.tbd", false);
		project.AddFrameworkToProject(target, "libz.tbd", false);
		project.AddFrameworkToProject(target, "libsqlite3.tbd", false);
		project.AddFrameworkToProject(target, "StoreKit.framework", false);
		project.AddFrameworkToProject(target, "SystemConfiguration.framework", false);
		project.AddFrameworkToProject(target, "CoreTelephony.framework", false);
		project.AddFrameworkToProject(target, "QuartzCore.framework", false);
		project.AddFrameworkToProject(target, "Security.framework", false);

		// 对所有的编译配置设置选项  
		project.SetBuildProperty(target, "ENABLE_BITCODE", "NO");
		project.AddBuildProperty(target, "OTHER_LDFLAGS", "-ObjC");

		// 保存工程  
		project.WriteToFile (projPath);  

		// 修改plist  
		string plistPath = path + "/Info.plist";  
		PlistDocument plist = new PlistDocument();  
		plist.ReadFromString(File.ReadAllText(plistPath));  

		//添加app信息到info.plist
		PlistElementDict rootDict = plist.root;  
		PlistElementDict SDKDic = rootDict.CreateDict("KSSDK");
		SDKDic.SetString ("APPID", "100000022");							 //CP填自己的appid
		SDKDic.SetString ("APPKey", "c824619ea987f124ebbb75ef79d85196");	 //CP填自己的appkey


		//添加分享的信息
		PlistElementArray array = rootDict.CreateArray("CFBundleURLTypes");
	
/*
		// 微信分享信息
		PlistElementDict dictWechat = array.AddDict();
		dictWechat.SetString("CFBundleURLName", "weixin");
		PlistElementArray arrayWechat = dictWechat.CreateArray("CFBundleURLSchemes");
		arrayWechat.AddString("wx21662a277bfda3a2");           				//CP填自己的wxappid

		// QQ分享信息
		PlistElementDict dictQQ = array.AddDict ();
		dictQQ.SetString ("CFBundleURLName", "tecnet");
		PlistElementArray arrayQQ = dictQQ.CreateArray("CFBundleURLSchemes");
		arrayQQ.AddString ("tecent222222");									//CP填自己的QQ id

		// 微博分享
		PlistElementDict dictWeibo = array.AddDict();
		dictWeibo.SetString("CFBundleURLName","weibo");
		PlistElementArray arrayWeibo = dictWeibo.CreateArray("CFBundleURLSchemes");
		arrayWeibo.AddString("wb2980459460");								//CP填写自己的微博id

		//银联信息
		PlistElementDict dictUP = array.AddDict();
		PlistElementArray arrayUP = dictUP.CreateArray ("CFBundleURLSchemes");
		arrayUP.AddString("KSUPPay");										//此值可以为任意值，但必须唯一
*/

		array = rootDict.CreateArray("LSApplicationQueriesSchemes");
		array.AddString("weixin");
		array.AddString("wechat");
		array.AddString ("weibosdk2.5");
		array.AddString ("weibosdk");
		array.AddString ("sinaweibo");
		array.AddString ("sinaweibohd");
		array.AddString ("mqq");
		array.AddString ("mqqapi");
		array.AddString ("mqqopensdkapiV2");
		array.AddString ("mqqbrowser");
		// 下面字段为自有支付相关
		array.AddString("uppayx1");
		array.AddString ("uppayx2");
		array.AddString ("uppayx3");
		array.AddString ("uppaywallet");
		array.AddString ("uppaysdk");

		// 语音所需要的声明
		rootDict.SetString("NSMicrophoneUsageDescription", "通过麦克风和其他玩家语音聊天"); 

		// 相册所需权限
		rootDict.SetString("NSPhotoLibraryAddUsageDescription","将账号密码保存至相册中");
		rootDict.SetString ("Privacy - Photo Library Usage Description", "将账号密码保存至相册中");

		//添加允许http访问
		PlistElementDict dict3 = rootDict.CreateDict("NSAppTransportSecurity");
		dict3.SetBoolean("NSAllowsArbitraryLoads", true);

		// save info.plist
		plist.WriteToFile(plistPath);

		EditUnityAppController(path);

		Debug.Log("Xcode修改完毕");
	}

	static void EditUnityAppController(string pathToBuiltProject)
	{
		string unityAppControllerPath = pathToBuiltProject + "/Classes/UnityAppController.mm";
		if (File.Exists(unityAppControllerPath))
		{
			string headerCode = "#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000\n" 
				+ "#import <UserNotifications/UserNotifications.h>\n"
				+ "#endif\n"
				+ "#import <KSProxy/KSProxy.h>\n";
			string unityAppController = headerCode + File.ReadAllText(unityAppControllerPath);

			Match match1 = Regex.Match(unityAppController, @"- \(void\)application:\(UIApplication\*\)application didReceiveRemoteNotification:\(NSDictionary\*\)userInfo\n{");
			if(match1.Success)
			{
				string newCode = match1.Groups [0].Value;
				newCode += "\n" +
					"    [[KSProxy shareInstance] didReceiveRemoteNotification:userInfo];\n" ;
				unityAppController = unityAppController.Replace(match1.Groups[0].Value, newCode);
			}

			Match match2 = Regex.Match(unityAppController, @"- \(BOOL\)application:\(UIApplication\*\)application openURL:\(NSURL\*\)url sourceApplication:\(NSString\*\)sourceApplication annotation:\(id\)annotation\n{");
			if(match2.Success)
			{
				string newCode = match2.Groups [0].Value;
				newCode += "\n" +
					"    [[KSProxy shareInstance] payResult:url completion:^(NSString *code, NSDictionary *data) {\n        NSLog(@\"paycode =  %@\",code);\n        NSLog(@\"paydata = %@\",data);\n    }];\n" ;
				unityAppController = unityAppController.Replace(match2.Groups[0].Value, newCode);
			}
				
			Match match3 = Regex.Match(unityAppController,@"- \(BOOL\)application:\(UIApplication\*\)application openURL:\(nonnull NSURL\*\)url options:\(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id>\*\)options");
			if (match3.Success) {
				string newCode = match3.Groups[0].Value;
				newCode += "\n" +
				"    [[KSProxy shareInstance] payResult:url completion:^(NSString *code, NSDictionary *data) {\n        NSLog(@\"paycode =  %@\",code);\n        NSLog(@\"paydata = %@\",data);\n    }];\n";
				unityAppController = unityAppController.Replace (match2.Groups [0].Value, newCode);
			} else {
				string newCode = "\n- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {\n\t[[KSProxy shareInstance] payResult:url completion:^(NSString *code, NSDictionary *data) {\n\t\tNSLog(@\"paycode =  %@\",code);\n\t\tNSLog(@\"paydata = %@\",data);\n\t}];\n\treturn [KSProxy handleOpenURL:url];\n}";
				unityAppController = unityAppController.Insert (unityAppController.LastIndexOf ("\n- (BOOL)application:(UIApplication*)application openURL"), newCode);
			}

			File.WriteAllText(unityAppControllerPath, unityAppController);
		}
	}

//	static void EditUnityRootViewController(string pathToBuildProject)
//	{
//		// 读取rootViewController路径，如果为自定义rootViewController，该路径需要修改
//		string UnityRootViewControllerPath = pathToBuildProject + "/Classes/UI/UnityViewControllerBaseiOS.mm";
//
//		string UnityRootViewControllerText = File.ReadAllText (UnityRootViewControllerPath);
//
//		if (File.Exists (UnityRootViewControllerPath)) 
//		{
//			string insertCode = "\n- (BOOL)shouldAutorotate\n{\n    return YES;\n}\n\n- (UIInterfaceOrientationMask)supportedInterfaceOrientations\n{\n    return UIInterfaceOrientationMaskLandscape;\n}\n";
//
//			UnityRootViewControllerText = UnityRootViewControllerText.Insert (UnityRootViewControllerText.LastIndexOf("- (id)initWithFrame"), insertCode);
//		}
//		File.WriteAllText (UnityRootViewControllerPath, UnityRootViewControllerText);
//	}
}

#endif
