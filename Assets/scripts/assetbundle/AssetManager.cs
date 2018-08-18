using AssetBundles;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.SceneManagement;

public class AssetManager
{
#region static const value

    public static string RootPath = "Assets/assetbundle";
    public const string simulatemode = "AssetManagerSimulateInEditor";
    public const string simulatelua = "AssetManagerSimulateLuaInEditor";
    public static int mSimulateMode = -1;
    public static int mSimulateLua = -1;

    public static bool unloadAll = true;

    public static bool SimulateMode
    {
#if UNITY_EDITOR
        get
        {
            if (mSimulateMode == -1)
                mSimulateMode = UnityEditor.EditorPrefs.GetBool(simulatemode, true) ? 1 : 0;

            return mSimulateMode != 0;
        }
        set
        {
            int newValue = value ? 1 : 0;
            if (newValue != mSimulateMode)
            {
                mSimulateMode = newValue;
                UnityEditor.EditorPrefs.SetBool(simulatemode, value);
            }
        }
#else
        get
        {
            return false;
        }
        set
        {
            
        }
#endif
    }

    public static bool SimulateLua
    {
#if UNITY_EDITOR
        get
        {
            if (mSimulateLua == -1)
                mSimulateLua = UnityEditor.EditorPrefs.GetBool(simulatelua, true) ? 1 : 0;

            return mSimulateLua != 0;
        }
        set
        {
            int newValue = value ? 1 : 0;
            if (newValue != mSimulateLua)
            {
                mSimulateLua = newValue;
                UnityEditor.EditorPrefs.SetBool(simulatelua, value);
            }
        }
#else
        get
        {
            return false;
        }
        set
        {
            
        }
#endif
    }

    static HashSet<string> mCommonAssets = new HashSet<string>();
    static Dictionary<string, int> mDepended = new Dictionary<string, int>();
    static Dictionary<string, Bundle> mAssetBundles = new Dictionary<string, Bundle>();
    static Dictionary<string, List<System.Action>> mSyncLoadingBundlesCallback = new Dictionary<string, List<System.Action>>();

    static Dictionary<string, string> mPatchs = new Dictionary<string, string>();
    static AssetBundleManifest mManifest;
    static Bundle mMainBundle;
    #endregion

    public static void AddPatch(string patch, string version)
    {
        if (mPatchs.ContainsKey(patch))
        {
            mPatchs[patch] = version;
        }
        else
        {
            mPatchs.Add(patch, version);
        }
    }

    public static string PathCombine(string path)
    {
        string ret = null;
        if (mPatchs.ContainsKey(path))
        {
            ret = Path.Combine(Application.persistentDataPath, mPatchs[path] + "/" + path);
        }
        else
        // else if (mBundles == null || mBundles.Contains(path))
        {
            ret = Path.Combine(Application.streamingAssetsPath, path);
        }
        // Debug.LogFormat("asset bundle path {0}, full path {1}", path, ret);

        return ret;
    }

    static bool CheckCommonAssets(string b)
    {
        return mCommonAssets.Contains(b);
    }
    
    public static void Init()
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            BundleInfoManager.Init();
        }else
#endif
        {
            mMainBundle = new Bundle(PathCombine(Utility.GetPlatformName()));
            mMainBundle.loadAssetBundle();
            mManifest = mMainBundle.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
            BundleInfoManager.Init();

            var bds = mManifest.GetAllAssetBundles();
            foreach (var bd in bds)
            {
                if (bd.IndexOf("common/") >= 0)
                {
                    mCommonAssets.Add(bd);
                }
                string[] deps = mManifest.GetDirectDependencies(bd);
                if (deps != null && deps.Length > 0)
                {
                    for (int k = 0; k < deps.Length; ++k)
                    {
                        string name = deps[k];
                        if (mDepended.ContainsKey(name))
                        {
                            mDepended[name] = mDepended[name] + 1;
                        }
                        else
                        {
                            mDepended.Add(name, 1);
                        }
                    }
                }
            }
        }

        foreach (var bd in mCommonAssets)
        {
            mDepended.Remove(bd);
            LoadAssetBundle(bd);
        }

        UnityEngine.SceneManagement.SceneManager.sceneLoaded += (Scene scene, LoadSceneMode mode) => {
            Debug.Log("SceneManager sceneLoaded:" + scene.name);
            // LoadDepenedBundle();
            Bundle.StartAsyncOperator();
            // SGK.ImageLoader.StartLoadThread();
            // Statistics.PreLoadAsset(scene.name);
        };

        UnityEngine.SceneManagement.SceneManager.sceneUnloaded += (Scene scene) =>
        {
            Debug.Log("SceneManager sceneLoaded unload:" + scene.name);
            // UnLoadDepenedBundle();
            // UnloadUnusedBundle();
        };
    }

    public static void Clear()
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            return;
        }
#endif
        foreach (var b in mAssetBundles)
        {
            b.Value.Unload(unloadAll, true);
        }
        mAssetBundles.Clear();
        mCommonAssets.Clear();
        mSyncLoadingBundlesCallback.Clear();

        mPatchs.Clear();
        mManifest = null;
        if (mMainBundle != null)
        {
            mMainBundle.Unload(unloadAll);
            mMainBundle = null;
        }
    }

    public static AsyncOperation UnloadAll(bool all = true)
    {
        List<Bundle> bs = new List<Bundle>();
        foreach (var b in mAssetBundles)
        {
            if (!CheckCommonAssets(b.Key))
            {
                b.Value.Unload(all, true);
            }
            else
            {
                bs.Add(b.Value);
            }
        }

        mAssetBundles.Clear();
        mSyncLoadingBundlesCallback.Clear();

        foreach (var b in bs)
        {
            mAssetBundles.Add(b.Asset.name, b);
        }

        return Resources.UnloadUnusedAssets();
    }
    
    public static void LoadDepenedBundle()
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            return;
        }
#endif
        foreach (var it in mDepended)
        {
            LoadAssetBundle(it.Key, false);
        }
    }
    
    public static void LoadScenes(string name)
    {
        Debug.Log("SceneManager LoadScenes:" + name);
#if UNITY_EDITOR
        if (SimulateMode)
        {
            return;
        }
#endif
        string ab = BundleInfoManager.GetBundleNameWithFullPath(name + ".unity");
        if (ab != null)
        {
            LoadAssetBundle(ab);
        }
    }

#region load asset bundle
    public static bool LoadAssetBundle(string name, bool force = true)
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            if (BundleInfoManager.CheckContainBundle(name))
            {
                return true;
            }
            else
            {
                Debug.LogErrorFormat("load asset bundle failed! asset bundle '{0}'", name);
                return false;
            }
        } 
#endif
        if (mAssetBundles.ContainsKey(name))
        {
            mAssetBundles[name].loadAssetBundle();
            return true;
        }

        Bundle b = new Bundle(PathCombine(name));
        if (!b.loadAssetBundle())
        {
            Debug.LogErrorFormat("load asset bundle failed! asset bundle '{0}'", name);
            return false;
        }
        mAssetBundles.Add(name, b);
        // Debug.LogFormat("load asset bundle '{0}'", name);
        if (force)
        {
            string[] deps = mManifest.GetAllDependencies(name);
            if (deps != null && deps.Length > 0)
            {
                for (int i = 0; i < deps.Length; ++i)
                {
                    LoadAssetBundle(deps[i], false);
                }
            }
        }
        
        return true;
    }

    public static IEnumerator LoadAssetBundleSync(MonoBehaviour mb, string name)
    {
#if UNITY_EDITOR
        if (!SimulateMode)
        {
#endif
            Bundle b = new Bundle(PathCombine(name));
            yield return mb.StartCoroutine(b.loadAssetBundleSync());
            if (b.Asset == null)
            {
                Debug.LogErrorFormat("load asset bundle async failed! asset bundle '{0}'", name);
            }
            else
            {
                mAssetBundles.Add(name, b);
                // Debug.LogFormat("load asset bundle '{0}'", name);

                string[] deps = mManifest.GetAllDependencies(name);
                if (deps != null && deps.Length > 0)
                {
                    for (int i = 0; i < deps.Length; ++i)
                    {
                        var dep = deps[i];
                        if (mAssetBundles.ContainsKey(dep))
                        {
                            mAssetBundles[dep].loadAssetBundle();
                        }
                        else
                        {
                            mb.StartCoroutine(LoadAssetBundleSync(mb, dep));
                        }
                    }
                }
            }
#if UNITY_EDITOR
        }
#endif
    }
#endregion

#region unload asset bundle
    public static void UnloadAssetBundle(string name, bool all, bool force = true)
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            if (!BundleInfoManager.CheckContainBundle(name))
            {
                Debug.LogWarningFormat("unload asset bundle failed! asset bundle '{0}'", name);
                return;
            }
        }
#endif
        Bundle b;
        
        if (CheckCommonAssets(name) ||!mAssetBundles.TryGetValue(name, out b))
        {
            return;
        }

        if (b.Unload(all))
        {
            mAssetBundles.Remove(name);
            mSyncLoadingBundlesCallback.Remove(name);
        }

        if (!force)
        {
            return;
        }

        string[] deps = mManifest.GetDirectDependencies(name);
        if (deps != null && deps.Length > 0)
        {
            for (int i = 0; i < deps.Length; ++i)
            {
                UnloadAssetBundle(deps[i], all, false);
            }
        }
    }

#endregion

#region load function
    // Assets/assetbundle/ + path
    public static T Load<T>(string path) where T : Object
    {
        Debug.Assert(!string.IsNullOrEmpty(path), string.Format("asset manager load fail!, path {0}, name {0}", path));

        T obj = null;
        string ab = BundleInfoManager.GetBundleNameWithFullPath(path);
        if (string.IsNullOrEmpty(ab))
        {
            return obj;
        }

#if UNITY_EDITOR
        if (SimulateMode)
        {
            if (!LoadAssetBundle(ab))
            {
                return null;
            }
            return UnityEditor.AssetDatabase.LoadAssetAtPath<T>(path);
        }
#endif
        if (!mAssetBundles.ContainsKey(ab) && !LoadAssetBundle(ab))
        {
            return obj;
        }
        obj = mAssetBundles[ab].LoadAsset<T>(path);

        return obj;
    }

    public static Object Load(string name)
    {
        return Load<Object>(name);
    }

    public static Object Load(string path, System.Type type)
    {
        Debug.Assert(!string.IsNullOrEmpty(path), string.Format("asset manager load fail!, path {0}, name {0}", path));
        Object obj = null;
        string ab = BundleInfoManager.GetBundleNameWithFullPath(path);
        if (string.IsNullOrEmpty(ab))
        {
            return obj;
        }
#if UNITY_EDITOR
        if (SimulateMode)
        {
            if (!LoadAssetBundle(ab))
            {
                return null;
            }

            return UnityEditor.AssetDatabase.LoadAssetAtPath(path, type);
        }
#endif
        if (!mAssetBundles.ContainsKey(ab) && !LoadAssetBundle(ab))
        {
            return obj;
        }

        obj = mAssetBundles[ab].LoadAsset(path, type);
        return obj;
    }

    public static void LoadAsync(MonoBehaviour mb, string path, System.Action<Object> callback)
    {
        LoadAsync(mb, path, typeof(Object), callback);
    }

    public static void LoadAsync(MonoBehaviour mb, string path, System.Type type, System.Action<Object> callback)
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            callback(Load(path, type));
            return;
        }
#endif
        string ab = BundleInfoManager.GetBundleNameWithFullPath(path);
        if (string.IsNullOrEmpty(ab))
        {
            if (callback != null)
            {
                callback(null);
            }
            return;
        }

        if (mAssetBundles.ContainsKey(ab))
        {
            mAssetBundles[ab].LoadAssetAsync(mb, path, type, callback);
        }
        else
        {
            if (LoadAssetBundle(ab))
            {
                mAssetBundles[ab].LoadAssetAsync(mb, path, type, callback);
            }
            /*
            List<System.Action> cbs = null;
            if (!mSyncLoadingBundlesCallback.TryGetValue(ab, out cbs))
            {
                cbs = new List<System.Action>();
                mSyncLoadingBundlesCallback.Add(ab, cbs);
                mb.StartCoroutine(LoadAssetBundleThread(mb, ab));
            }
            cbs.Add(() =>
            {
                mAssetBundles[ab].LoadAssetAsync(mb, path, type, callback);
            });
            */
        }
    }

    static IEnumerator LoadAssetBundleThread(MonoBehaviour mb, string ab)
    {
        yield return mb.StartCoroutine(LoadAssetBundleSync(mb, ab));
        var cbs = mSyncLoadingBundlesCallback[ab];

        for (int i = 0; i < cbs.Count; ++i)
        {
            cbs[i]();
        }
        mSyncLoadingBundlesCallback.Remove(ab);
    }

    public static TextAsset LoadTextAsset(string name)
    {
        return Load<TextAsset>(name);
    }

    public static Sprite LoadSpriteMultiple(string path, string sub)
    {
        string ab = BundleInfoManager.GetBundleNameWithFullPath(path);
        if (string.IsNullOrEmpty(ab))
        {
            return null;
        }
#if UNITY_EDITOR
        if (SimulateMode)
        {
            Object[] objs = UnityEditor.AssetDatabase.LoadAllAssetsAtPath(path);
            for (int i = 0; i < objs.Length; ++ i)
            {
                if (objs[i].name == sub)
                {
                    return objs[i] as Sprite;
                }
            }
            return null;
        }
#endif
        Object obj = null;
        if (!mAssetBundles.ContainsKey(ab) && !LoadAssetBundle(ab))
        {
            Debug.LogWarningFormat("load asset failed! '{0}', asset bundle load failed '{1}'!", path, ab);
            return null;
        }
        obj = mAssetBundles[ab].LoadAssetWithSubAssets(path, sub);

        if (obj == null)
        {
            Debug.LogWarningFormat("load asset failed! '{0}'", path);
            return null;
        }
       
        return obj as Sprite;
    }

    public static T LoadAssetWithBundle<T>(string ab, string name) where T : Object
    {
        Debug.Assert(ab != null && name != null, string.Format("asset manager load fail!, path {0}, name {0}", ab, name));
#if UNITY_EDITOR
        if (SimulateMode)
        {
            if (!LoadAssetBundle(ab))
            {
                return null;
            }
            return UnityEditor.AssetDatabase.LoadAssetAtPath<T>(name);
        }
#endif
        T obj = null;
        if (!mAssetBundles.ContainsKey(ab) && !LoadAssetBundle(ab, false))
        {
            return obj;
        }
        obj = mAssetBundles[ab].LoadAsset<T>(name);

        return obj;
    }
#endregion
}
