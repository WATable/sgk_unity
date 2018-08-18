using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

[XLua.LuaCallCSharp]
public class SDKScript : MonoBehaviour {
	public GameObject [] waitingObject = new GameObject[0];


#if UNITY_IOS
	//定义iOS回调的事件名称
	public const int callbackInitEvent = 0; //初始化
	public const int callbackLoginEvent = 1; //登录
	public const int callbackLogoutEvent = 2; //登出
	public const int callbackPayEvent = 3; //支付
	public const int callbackInituserCenter = 4; // 用户中心初始化
	public const int callbackUploadFile = 5; // 录音完成
	public const int callbackSpeechToText = 6; // 翻译完成

	public const string callbackMethodSuccess = "10000";//Android回调 - 成功状态对应方法

	string fileID = "";//语音文件id

	//初始化
	[DllImport("__Internal")]
	private static extern void _PlatformInit(string appid,string appkey);
	[DllImport("__Internal")]
	private static extern void _PlatformInitBugly(string appid);
	[DllImport("__Internal")]
	private static extern void _PlatformInitReyun(string appkey);
	[DllImport("__Internal")]
	private static extern void _PlatformInitPush(string appkey);

	//业务方法
	[DllImport("__Internal")]
	private static extern void _PlatformLogin();
	[DllImport("__Internal")]
	private static extern void _PlatformPay(string payInfo);
	[DllImport("__Internal")]
	private static extern void _PlatformLogout();
	[DllImport("__Internal")]
	private static extern void _PlatformChangeout();
	[DllImport("__Internal")]
	private static extern void _PlatformInituserCenter();
	[DllImport("__Internal")]
	private static extern void _PlatformSetRootView();
	[DllImport("__Internal")]
	private static extern void _PlatformShowCustomService(string Info);

	//实时语音
	[DllImport("__Internal")]
	private static extern void _PlatformInitVoice(string appid,string appkey,string playerID);
	[DllImport("__Internal")]
	private static extern void _PlatformJoinTeamRoom(string roomID);
	[DllImport("__Internal")]
	private static extern void _PlatformJoinNationalRoom(string roomID,int role);
	[DllImport("__Internal")]
	private static extern void _PlatformQuitTeamRoom(string roomID);
	[DllImport("__Internal")]
	private static extern void _PlatformOpenSpeaker(bool on);
	[DllImport("__Internal")]
	private static extern void _PlatformOpenMIC(bool on);

	//微信分享
	[DllImport("__Internal")]
	private static extern void _PlatformInitWechat(string  WXAppid);
	[DllImport("__Internal")]
	private static extern void _PlatformShareMessage(string content,string title,string url,string imageName);
	[DllImport("__Internal")]
	private static extern void _PlatformShareFriends(string content,string title,string url,string imageName);
	//微博分享
	[DllImport("__Internal")]
	private static extern void _PlatformInitWeibo(string weiboId,string redirectUrl);
	[DllImport("__Internal")]
	private static extern void _PlatformShareWeibo(string content,string title,string url,string imageName);
	//qq分享
	[DllImport("__Internal")]
	private static extern void _PlatformInitQQ (string QQId);
	[DllImport("__Internal")]
	private static extern void _PlatformShareQQSpace(string content,string title,string url,string imageName);
	[DllImport("__Internal")]
	private static extern void _PlatformShareQQ(string content,string title,string url,string imageName);

	//语音消息
	[DllImport("__Internal")]
	private static extern void _PlatformStartRecording();
	[DllImport("__Internal")]
	private static extern void _PlatformStopRecording();
	[DllImport("__Internal")]
	private static extern void _PlatformPlayRecordedFile(string fileID);
	[DllImport("__Internal")]
	private static extern void _PlatformStopPlayFile();

	//语音翻译成文字
	[DllImport("__Internal")]
	private static extern void _PlatforminitSpeechToText();
	[DllImport("__Internal")]
	private static extern void _PlatformStartSpeech();
	[DllImport("__Internal")]
	private static extern void _PlatformSpeechToText(string fileID);
	static SDKScript jo = null;
#else
	// Use this for initialization
	//定义Android回调的事件名称
	public const int callbackInitEvent = 0; //初始化
	public const int callbackLoginEvent = 1; //登录
	public const int callbackLogoutEvent = 2; //登出
	public const int callbackPayEvent = 3; //支付
	// public const int callbackInitUserCenter = 4; // 用户中心初始化

	//定义Android回调是成功方法还是失败方法
	public const string callbackMethodSuccess = "0";//Android回调 - 成功状态对应方法
	// public const string callbackMethodFail = "-1"; //Android回调 - 失败状态对应方法
	// public const string callbackMethodCancel = "-2";//Android 回调 - 取消状态对应方
	static AndroidJavaObject jo = null;
#endif

	void Start () {
		if (Application.isEditor) {
			ActiveAll();
			return;
		}

		
#if UNITY_ANDROID
		if (jo == null) {
			Debug.Log("start init sdk");
			AndroidJavaClass jc = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
			jo = jc.GetStatic<AndroidJavaObject>("currentActivity");
			this.name = "KSAndroidCallback";
		} else {
			ActiveAll();
		}
#elif UNITY_IOS
		if (jo == null) {
			jo = this;
			_PlatformSetRootView();
			_PlatformInit("100000001","c05ddaa41ed4e149978dc33ed6cb680c");
			this.name = "KaiserCallBack";
		} else {
			ActiveAll();
		}
#else
		ActiveAll();
#endif
	}

	void ActiveAll() {
        UnityEngine.SceneManagement.SceneManager.LoadScene(SGK.SceneService.PRESISTENT_SCENE_BUILD_INDEX);
        /*
        for (int i = 0; i < waitingObject.Length; i++) {
			waitingObject[i].SetActive(true);
		}
        */
	}

	public static bool isEnabled {
		get {
			return (jo != null);
		}
	}

	public static void Login() {
		if (jo == null) {
			return;
		}
#if UNITY_ANDROID
		Call("login");
#elif UNITY_IOS
		_PlatformLogin();
#endif
	}

	public struct PayInfo {
		public string uid; 		 // 游戏账号uid
		public string price;        // 商品价格（元）

		public string productId;    // 商品ID
		public string productName;  // 商品名称（如：50钻石）
		public string productDesc;	 // 商品描述

		public string cpOrderId;    // 游戏商品订单号

		public string serverId;     // 服务器ID
		public string serverName;   // 区服名称
		public string roleId;          // 游戏角色ID
		public string roleLevel;        // 角色等级
		public string roleName;     // 角色名称

		public string currencyName;  // 货币名称
		public string exchangeRate;  // 货币对人民币比率

		public string ext;     // 透传字段，供游戏cp使用，回调时会原样返回
	}

	public class SDKCallbackObject
	{
		public int callBackEvent;

		public string uid;
		public string openId;
		public string msg;
		public string code;
	}

	public static void Pay(PayInfo info) {
		if (jo == null) {
			return;
		}
#if UNITY_ANDROID
		string [] objectPrrams = new string[14];
		objectPrrams[ 0] = info.currencyName;
		objectPrrams[ 1] = info.exchangeRate;
		objectPrrams[ 2] = info.cpOrderId;
		objectPrrams[ 3] = info.price;
		objectPrrams[ 4] = info.productName;
		objectPrrams[ 5] = info.productId;
		objectPrrams[ 6] = info.productDesc;
		objectPrrams[ 7] = info.ext;
		objectPrrams[ 8] = info.uid;
		objectPrrams[ 9] = info.roleId;
		objectPrrams[10] = info.serverId;
		objectPrrams[11] = info.roleLevel;
		objectPrrams[12] = info.serverName;
		objectPrrams[13] = info.roleName;

		Call("pay", objectPrrams);
#elif UNITY_IOS
		KaiserPay payInfo = new KaiserPay();
		payInfo.cp_orderno  = info.cpOrderId;
		payInfo.product_id  = info.productId;
		payInfo.price       = info.price;
		payInfo.project     = info.productName;
		payInfo.ext_info    = info.ext;
		payInfo.rid         = info.roleId;
		payInfo.level       = info.roleLevel;
		payInfo.serverId    = info.serverId;
		payInfo.uid         = info.uid;
		payInfo.desc        = info.productDesc;
		
		_PlatformPay( JsonUtility.ToJson(payInfo).ToString() );
#endif
	}

#if UNITY_ANDROID
	void KSAndroidCallback(string str) 
	{
		Debug.LogFormat("KSAndroidCallback {0}", str);
		KSAndroidCallbackObj obj = JsonUtility.FromJson<KSAndroidCallbackObj> (str);
		SGK.LuaController.DispatchEvent("SDK_CALLBACK", obj);

        if (obj.callBackEvent == callbackInitEvent) {
            SGK.PatchManager.sdk_channel = obj.channel;
        }

        SDKCallbackObject sobj = new SDKCallbackObject();
		sobj.callBackEvent = obj.callBackEvent;

		sobj.uid = obj.uid;
		sobj.openId = obj.openId;
		sobj.msg = obj.msg;
		sobj.code = obj.code;

		onSDKCallback(sobj);
	}

	public static void Call(string func, string [] args = null) {
		if (jo == null) {
			return;
		}

		if (args == null) {
			jo.Call(func);
		} else {
			jo.Call(func, args);
		}
	}

#elif UNITY_IOS
	void KaiserCallBack(string str) 
	{
		Debug.LogFormat("KaiserCallback {0}", str);
		KaiserCallBackObject obj = JsonUtility.FromJson<KaiserCallBackObject> (str);
		SGK.LuaController.DispatchEvent("SDK_CALLBACK", obj);

		SDKCallbackObject sobj = new SDKCallbackObject();
		sobj.callBackEvent = obj.callBackEvent;

		sobj.uid = obj.uid;
		sobj.openId = obj.openId;
		sobj.msg = obj.msg;
		sobj.code = obj.code;

		onSDKCallback(sobj);
	}

	public static void Call(string func, string [] args) {
	}
#endif

	void onSDKCallback(SDKCallbackObject obj) {
		switch (obj.callBackEvent) {
		//监听初始化结果
		case callbackInitEvent:
			KSInitResult (obj);
			break;
	    //监听登录结果
		case callbackLoginEvent:
			KSLoginResult (obj);
			break;
		//监听登出结果
		case callbackLogoutEvent:
			KSLogoutResult (obj);
			break;
		//监听支付结果
		case callbackPayEvent:
			KSPayResult (obj);
			break;
		} 
	}

	//初始化监听
	void KSInitResult(SDKCallbackObject obj){
		bool isSuccess = true;
#if UNITY_ANDROID
		isSuccess = obj.code.Equals(callbackMethodSuccess);
#endif
		if (isSuccess) {
			Debug.Log("初始化成功");
			ActiveAll();
		} else {
			Debug.LogFormat("初始化失败 {0}", obj.code);
		}
	}

	//登录监听
	void KSLoginResult(SDKCallbackObject obj){
		if (obj.code.Equals(callbackMethodSuccess)) {
			Debug.Log("登录成功：" + obj.uid + " : " + obj.openId);
			SGK.LuaController.DispatchEvent("SDK_LOGIN_SUCCESS", obj.uid, obj.openId);
		} else {
			Debug.Log("登录失败: " + obj.code + " : " + obj.msg);
			SGK.LuaController.DispatchEvent("SDK_LOGIN_FAILED", obj.code, obj.msg);
		}
	}

	//登出监听
	void KSLogoutResult(SDKCallbackObject obj){
		if (obj.code.Equals(callbackMethodSuccess)) {
			Debug.Log("登出成功");
			UnityEngine.SceneManagement.SceneManager.LoadScene(0);
		} else {
			Debug.LogFormat("登出失败 {0}", obj.code);
		}
	}

	//支付监听
	void KSPayResult(SDKCallbackObject obj){
		//成功回调
		if (obj.code.Equals(callbackMethodSuccess)) {
			Debug.Log("支付成功 : " + obj.code);
		} else {
			Debug.Log("支付失败: " + obj.code);
		}
	}
}
