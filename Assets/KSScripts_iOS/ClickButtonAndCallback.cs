using UnityEngine;  
using System.Collections;  
using System.Runtime.InteropServices;  
using UnityEngine.UI;  

public class ClickButtonAndCallback : MonoBehaviour {  

	//定义iOS回调的事件名称
	public const int callbackInitEvent = 0; //初始化
	public const int callbackLoginEvent = 1; //登录
	public const int callbackLogoutEvent = 2; //登出
	public const int callbackPayEvent = 3; //支付
	public const int callbackInituserCenter = 4; // 用户中心初始化
	public const int callbackUploadFile = 5; // 录音完成
	public const int callbackSpeechToText = 6; // 翻译完成

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

	// Use this for initialization  
	void Start () {  
		//设置根视图
		_PlatformSetRootView();
		// 本Demo中的所有app参数都仅限于Demo自用，游戏的app参数需要找运营申请
		// 正式环境 :   100000001 c05ddaa41ed4e149978dc33ed6cb680c
		_PlatformInit("100000001","c05ddaa41ed4e149978dc33ed6cb680c");

		//初始化bugly
		//游戏的app参数需要找运营申请
		_PlatformInitBugly("32cbd6c83d");

		//初始化热云广告
		//游戏的app参数需要找运营申请
		_PlatformInitReyun("475938c702f7451a88eaffb524962649");

		//初始化消息推送，包名和证书要对应，还要在Xcode中开启push的能力
		//游戏的app参数需要找运营申请
		_PlatformInitPush("592e7734310c933fbc001200");

		//初始化微信分享,测试包名: com.kaiser.sdk.demo.Demo 测试appid: wx3c686f7b343f6921,
		//需设置Xcode的URL types，详见XCodePostProcess（已经自动配置好了）
		//游戏的app参数需要找运营申请
		_PlatformInitWechat("wx21662a277bfda3a2");
		_PlatformInitQQ ("222222");
		_PlatformInitWeibo ("2980459460","http://heheda.com");

		this.name = "KaiserCallBack";
	}  

	// Update is called once per frame  
	void Update () {  

	}  

	void OnGUI()  
	{  
		if(GUI.Button(new Rect(0,10,300,80),"登录"))  
		{  
			print("登录"); 
			_PlatformLogin(); 
		}  
		if(GUI.Button(new Rect(320,10,300,80),"支付"))  
		{  
			print("支付");
			KaiserPay payInfo = new KaiserPay();
			payInfo.rid = "1101";
			payInfo.cp_orderno = "201704038282891823123123";//cp_orderNO
			payInfo.ext_info = "game_name";
			payInfo.level = "15";
			payInfo.price = "12";
			payInfo.product_id = "com.Kaiser.test";
			payInfo.project = "50蓝砖石";
			payInfo.serverId = "221.221.2.2";
			payInfo.uid = "1313123";
			payInfo.desc = @"商品描述";
			string pay = JsonUtility.ToJson(payInfo).ToString();
			_PlatformPay(pay);
		}

		if(GUI.Button(new Rect(640,10,300,80),"登出"))  
		{  
			print("登出");
			_PlatformLogout();
		}
		if(GUI.Button(new Rect(0,100,350,80),"显示用户中心"))  
		{  
			print("显示用户中心");
			_PlatformInituserCenter();
		} 
		if(GUI.Button(new Rect(400,100,350,80),"切换账号"))  
		{  
			print("切换账号");
			_PlatformChangeout();
		}
		if (GUI.Button(new Rect(800, 100, 100, 80), "客服"))
		{
			print("客服");
			KSCustomerInfo info = new KSCustomerInfo();
			info.serverId = "10000";
			info.serverName = "10000";
			info.roleId = "10000";
			info.roleName = "10000";

			string pay = JsonUtility.ToJson(info).ToString();
			_PlatformShowCustomService(pay);
		}
		if (GUI.Button(new Rect(0, 370, 100, 80), "初始化语音"))
		{
			print("初始化语音");
			//开启实时语音sdk 第一步：注册 （玩家id和房间号都由cp决定）
			int playerid = Random.Range(1000,2000);
			string roomid = "12345";
			_PlatformInitVoice("1092898629","e6acdaaff65ee854ac4d47f617bba912",playerid.ToString());

			//开启实时语音sdk 第二步：加入房间（有两种房间，小队房间和全服房间。如果一个房间内同时聊天的玩家小于20人，则使用小队语音模式，这时玩家可以自由发言。
			//当一个房间内语音聊天的玩家大于20人时，则使用全服语音，同时说话人数上限为5人（该模式常用于主播，解说，指挥等）
			_PlatformJoinTeamRoom(roomid); //团队语音
			//			_PlatformJoinNationalRoom("teamNo1",1); //国战（全服）语音
		}
		if (GUI.Button(new Rect(200, 370, 100, 80), "开启语音"))
		{
			print("开启语音");
			//开启实时语音sdk 第三步：设置硬件开关，两台设备间的测试距离最好大于100米
			_PlatformOpenSpeaker(true);
			_PlatformOpenMIC(true);
		}
		if (GUI.Button(new Rect(400, 370, 100, 80), "退出房间"))
		{
			print("退出房间");
			string roomid = "12345";
			_PlatformQuitTeamRoom(roomid);
		}
		if (GUI.Button(new Rect(600, 370, 100, 80), "关闭语音"))
		{
			print("关闭语音");
			_PlatformOpenSpeaker(false);
			_PlatformOpenMIC(false);
		}
		if (GUI.Button(new Rect(0, 460, 100, 80), "分享给好友"))
		{
			print("分享给好友");
			_PlatformShareMessage("这是一个分享","分享测试","www.baidu.com","Icon.png");//传图片名称，就是分享图片
		}
		if (GUI.Button(new Rect(100, 460, 100, 80), "分享到朋友圈"))
		{
			print("分享到朋友圈");
			_PlatformShareFriends("这是一个分享","分享测试","www.baidu.com",null);//不传图片名称，就是分享文字
		}
		if (GUI.Button (new Rect (200, 460, 100, 80), "分享微博")) 
		{
			print ("分享到微博");
			_PlatformShareWeibo ("这是一个分享","分享测试","www.baidu.com",null);
		}
		if (GUI.Button (new Rect (0, 560, 100, 80),"分享到QQ")) 
		{
			print ("分享到QQ");
			_PlatformShareQQ ("这是一个分享","分享测试","www.baidu.com",null);
		}

		if (GUI.Button (new Rect (100, 560, 100, 80),"分享到QQ空间")) 
		{
			print ("分享到QQ空间");
			_PlatformShareQQSpace ("这是一个分享","分享测试","www.baidu.com",null);
		}
		//语音消息
		if (GUI.Button(new Rect(0, 190, 100, 80), "开始录制"))
		{
			print("开始录制");
			_PlatformStartRecording();
		}
		if (GUI.Button(new Rect(140, 190, 100, 80), "停止录制"))
		{
			print("停止录制");
			_PlatformStopRecording();
		}
		if (GUI.Button(new Rect(280, 190, 100, 80), "播放录音"))
		{
			print("播放录音");
			if (fileID != null && fileID != "") {
				_PlatformPlayRecordedFile(fileID);
			}
		}
		if (GUI.Button(new Rect(420, 190, 100, 80), "停止播放"))
		{
			print("停止播放");
			_PlatformStopPlayFile();
		}

		//语音翻译
		if (GUI.Button(new Rect(0, 280, 100, 80), "初始化翻译"))
		{
			print("初始化翻译");
			_PlatforminitSpeechToText();
		}
		if (GUI.Button(new Rect(140, 280, 100, 80), "开始说话"))
		{
			print("开始说话");
			_PlatformStartSpeech();
		}
		if (GUI.Button(new Rect(280, 280, 100, 80), "停止说话"))
		{
			print("停止录制");
			_PlatformStopRecording();
		}
		if (GUI.Button(new Rect(420, 280, 100, 80), "转成文字"))
		{
			print("转成文字");
			if (fileID != null && fileID != "") {
				_PlatformSpeechToText(fileID);
			}
		}
    }

	void KaiserCallBack(string str) {

		KaiserCallBackObject obj = JsonUtility.FromJson<KaiserCallBackObject> (str);

		switch (obj.callBackEvent) {
			case callbackInitEvent:	
				KaiserInitCallback (obj);
				break;
			case callbackLoginEvent:
				KaiserLoginCallback (obj);
				break;
			case callbackLogoutEvent:
				KaiserLogoutCallback (obj);
				break;
			case callbackPayEvent:
				KaiserPayCallback (obj);
				break;
			case callbackInituserCenter:
				KaiserInitUserCenterCallback(obj);
				break;
			case callbackUploadFile:
				fileID = obj.fileID;//语音文件的唯一标识
				UploadFileCallback(obj);
				break;
			case callbackSpeechToText:
				SpeechToTextCallback(obj);
				break;
		}
	}

	/******   以下是CP需要处理的回调方法   ******/
	//初始化监听
	void KaiserInitCallback(KaiserCallBackObject obj){
		print(obj);
	}

	//登录监听
	void KaiserLoginCallback(KaiserCallBackObject obj){
		print("登录返回值：");
		print(obj.uid);
		print(obj.username);
		print(obj.openId);
	}

	//登出监听
	void KaiserLogoutCallback(KaiserCallBackObject obj){
		print(obj);
	}

	//支付监听
	void KaiserPayCallback(KaiserCallBackObject obj){
		print(obj);
	}

	// 用户中心初始化
	void KaiserInitUserCenterCallback(KaiserCallBackObject obj) {
		print(obj);
	}

	// 语音消息上传完成通知
	void UploadFileCallback(KaiserCallBackObject obj) {
		print(obj);
	}

	// 语音消息转文字
	void SpeechToTextCallback(KaiserCallBackObject obj) {
		print(obj);
	}
}  
