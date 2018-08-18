using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.U2D;
using UnityEngine.UI;
using Spine.Unity;

namespace SGK {
	public class ImageLoader : MonoBehaviour {
		public SpriteRenderer spriteRenderer;
		public Image image;

		public string imageName;
		public string atlasName;

		System.Action<Sprite> callback;


        static List<ImageLoader> LoadList = new List<ImageLoader>();
        public static int Number = 1;
        static IEnumerator LoadThread()
        {
            do 
            {
                if (LoadList.Count > 0)
                {
                    int c = LoadList.Count > Number ? Number : LoadList.Count;
                    for (int i = 0; i < c; ++i)
                    {
                        LoadList[i].DoLoad();
                    }
                    for (int i = 0; i < c; ++i)
                    {
                        LoadList.RemoveAt(0);
                    }
                }

                yield return null;
            } while (true);
        }




        public static void Load(Image image, string name, System.Action<Sprite> callback = null, string atlasName = null) {
#if UNITY_EDITOR
			if (!Application.isPlaying) {
				image.sprite = SGK.ResourcesManager.Load<Sprite>(name);
				if(callback != null) {
					callback(image.sprite);
				}
				return;
			}
#endif

			if (image != null && image.sprite == null) {
				image.GetComponent<CanvasRenderer>().SetAlpha(0);
			}

            ImageLoader loader = image.gameObject.GetComponent<ImageLoader>();
			if (loader != null) {
                Destroy(loader);
            }

            loader = image.gameObject.AddComponent<ImageLoader>();

            loader.image = image;
			loader.imageName = name;
			loader.atlasName = atlasName;
			loader.callback = callback;
		}

        public static void StartLoadThread()
        {
            ResourcesManager.GetLoader().StartCoroutine(LoadThread());
        }

		public static void Load(SpriteRenderer renderer, string name, System.Action<Sprite> callback = null, string atlasName = null) {
#if UNITY_EDITOR
			if (!Application.isPlaying) {
				renderer.sprite = SGK.ResourcesManager.Load<Sprite>(name);
				if(callback != null) {
					callback(renderer.sprite);
				}
				return;
			}
#endif
            ImageLoader loader = renderer.gameObject.GetComponent<ImageLoader>();
			if (loader != null) {
				loader = renderer.gameObject.AddComponent<ImageLoader>();
			}

            loader.spriteRenderer = renderer;
			loader.imageName = name;
			loader.atlasName = atlasName;
			loader.callback = callback;
		}

        private void Start() {
            // LoadList.Add(this);
            DoLoad();
        }

        void DoLoad() { 
			if (!string.IsNullOrEmpty(imageName)) {
				StartAsyncLoad(this, this.image, imageName, callback, atlasName);
			} else if (callback != null) {
                callback(null);
            }
		}

		static void SyncLoadSprite(MonoBehaviour mb, string name, string atlasName, System.Action<Sprite> callback) {
            if (name == "0" || string.IsNullOrEmpty(name)) {
                callback(null);
                return;
            }

            if (string.IsNullOrEmpty(atlasName)) {
				SGK.ResourcesManager.LoadAsync(mb, name, typeof(Sprite), (o) => {
                    callback(o as Sprite);
                    /*
                    Sprite sp = null;
                    Texture2D tex = o as Texture2D;
                    if (tex != null)
                    {
                        sp = Sprite.Create(tex, new Rect(0f, 0f, tex.width, tex.height), Vector2.zero);
                    }
                    callback(sp); 
                    */
                });
			} else {
				SGK.ResourcesManager.LoadAsync(mb, atlasName, typeof(SpriteAtlas), (o) => {
					SpriteAtlas sa = o as SpriteAtlas;
					if (sa != null) {
						callback(sa.GetSprite(name));
					}
				});
			}
		}

		static void StartAsyncLoad(ImageLoader loader, Image image, string name, System.Action<Sprite> callback = null, string atlasName = null) {
			if (image == null && (loader == null || loader.spriteRenderer == null)) {
				return;
			}

			MonoBehaviour mb = loader;
			if (loader == null) {
				mb = image;
			}

			SyncLoadSprite(mb, name, atlasName, (o) => {
				if (o == null) {
					Debug.LogErrorFormat("sprite {0} not exists", name);
					return;
				}

				if (loader != null && loader.imageName != name) {
					Debug.LogErrorFormat("sprite {0}/{1} not match", name, loader.imageName);
					return;
				}

				if (image != null) {
					image.GetComponent<CanvasRenderer>().SetAlpha(1);
					image.sprite = o as Sprite;
				}

				if (loader != null && loader.spriteRenderer != null) {
					loader.spriteRenderer.sprite = o as Sprite;
				}

				if (callback != null) {
					callback(o as Sprite);
				}
			});
		}

		static void StartAsyncLoad(ImageLoader loader, string name, System.Action<Sprite> callback = null, string atlasName = null) {
			if (loader == null || loader.spriteRenderer == null) {
				return;
			}

			SyncLoadSprite(loader, name, atlasName, (o) => {
				if (o == null) {
					Debug.LogErrorFormat("sprite {0} not exists", name);
					return;
				}

				loader.spriteRenderer.sprite = o as Sprite;
				if (callback != null) {
					callback(o as Sprite);
				}
			});
		}
	}

	[XLua.LuaCallCSharp]
	public static class ImageExtension {
		public static void LoadSprite(this Image image, string name) {	
			ImageLoader.Load(image, name);
		}

		public static void LoadSprite(this Image image, string name, bool nativeSize) {
			ImageLoader.Load(image, name, (o) => {
				image.SetNativeSize();
			});
		}

		public static void LoadSprite(this Image image, string name, Color color) {
			ImageLoader.Load(image, name, (o) => {
				image.color = color;
			});
		}
		public static void LoadSprite(this Image image, string name, System.Action callback = null) {
			ImageLoader.Load(image, name, (o) => {
				if (callback != null){
					callback();
                    callback = null;
				}
			});
		}

		public static void LoadSprite(this Image image, string name, string atlasName) {
			ImageLoader.Load(image, name, null, atlasName);
		}

		public static void LoadSprite(this SpriteRenderer renderer, string name) {
			ImageLoader loader = renderer.gameObject.GetComponent<ImageLoader>();
			if (loader == null) {
				loader = renderer.gameObject.AddComponent<ImageLoader>();
			}

			ImageLoader.Load(renderer, name);
		}
    }
}
