using System;
using UnityEngine;
using System.Collections;
using VoxelBusters.NativePlugins;

namespace SGK
{   
    public class NoticeWebView : MonoBehaviour
    {
        private string m_url= "http://ndss.cosyjoy.com/sgk/login/announcement.php?platform=Android&v=0.1.9&t=dev&c=0/";
        private WebView m_webview;
        public void Start()
        {
#if UNITY_ANDROID || UNITY_IOS
            // Cache instances
            m_webview = gameObject.GetComponent<WebView>();
            if (m_webview==null)
            {
                m_webview = gameObject.AddComponent<WebView>();
            }
     
            // Set frame
            if (m_webview != null)
            m_webview.Frame = new Rect(64 * Screen.width / 750, 160 * Screen.width / 750, 621 * Screen.width / 750, 805 * Screen.width / 750);
            m_webview.LoadRequest(m_url);
            m_webview.Hide();  
            // Registering callbacks
   
            WebView.DidFinishLoadEvent += DidFinishLoadEvent;
            WebView.DidFailLoadWithErrorEvent += DidFailLoadWithErrorEvent;
#endif
        }

        public void OnDisable()
        {
#if UNITY_ANDROID || UNITY_IOS
            // Deregistering callbacks
            WebView.DidFinishLoadEvent -= DidFinishLoadEvent;
            WebView.DidFailLoadWithErrorEvent -= DidFailLoadWithErrorEvent;

            m_webview.ClearCache();
            m_webview.Destroy();
#endif
        }


        private void DidFinishLoadEvent(WebView _webview)
        {
#if UNITY_ANDROID || UNITY_IOS
            Debug.Log("Finished loading webpage contents.");
            m_webview.Show();
#endif
        }
        private void DidFailLoadWithErrorEvent(WebView _webview, string _error)
        {
   
            Debug.Log("Failed to load requested contents.");
            //AppendResult(string.Format("Error: {0}.", _error));
        }
    }    
}
