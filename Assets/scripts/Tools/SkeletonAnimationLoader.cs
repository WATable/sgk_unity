using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.U2D;
using UnityEngine.UI;
using Spine.Unity;

namespace SGK {
	public class SkeletonAnimationLoader : MonoBehaviour {
		static void AfterLoad(SkeletonAnimation skeletonAnimation, SkeletonDataAsset skeletonDataAsset, string [] actions = null, bool flip = false) {
            skeletonAnimation.skeletonDataAsset = skeletonDataAsset;
            skeletonAnimation.Initialize(true);
            if (skeletonAnimation.state != null && actions != null) {
                for (int i = 0; i < actions.Length; i++) {
                    if (!string.IsNullOrEmpty(actions[i])) {
                        if (i == 0) {
                            skeletonAnimation.state.SetAnimation(0, actions[i], (i == (actions.Length - 1)));
                        } else {
                            skeletonAnimation.state.AddAnimation(0, actions[i], (i == (actions.Length - 1)), 0);
                        }
                    }
                }
            }
			if (skeletonAnimation.skeleton != null && flip) {
				skeletonAnimation.skeleton.FlipX = flip;
			}
            MaskableSkeletonAnimation msa = skeletonAnimation.gameObject.GetComponent<MaskableSkeletonAnimation>();
            if (msa != null) {
                msa.UpdateStencil();
            }
        }

		public static void Load(SkeletonAnimation skeletonAnimation, string name, string[] actions = null, bool flip = false) {
            if (string.IsNullOrEmpty(name)) {
				AfterLoad(skeletonAnimation, null, actions, flip);
                return;
            }

#if UNITY_EDITOR
			if (!Application.isPlaying) {
                skeletonAnimation.skeletonDataAsset = SGK.ResourcesManager.Load<SkeletonDataAsset>(name);
                skeletonAnimation.Initialize(true);
                if (skeletonAnimation.state != null && actions != null) {
                    for (int i = 0; i < actions.Length; i++) { 
                        if (!string.IsNullOrEmpty(actions[i])) { 
                            if (i == 0) {
                                skeletonAnimation.state.SetAnimation(0, actions[i], (i == (actions.Length - 1)));
                            } else {
                                skeletonAnimation.state.AddAnimation(0, actions[i], (i == (actions.Length - 1)), 0);
                            }
                        }
                    }
                }
                return;
			}
#endif
            SkeletonAnimationLoader loader = skeletonAnimation.gameObject.GetComponent<SkeletonAnimationLoader>();
			if (loader != null) {
                Destroy(loader);
			}

            loader = skeletonAnimation.gameObject.AddComponent<SkeletonAnimationLoader>();
            loader.skeletonAnimation = skeletonAnimation;
			loader.fileName = name;
			loader.actions = actions;
			loader.flip = flip;
		}

        public SkeletonAnimation skeletonAnimation;
        public string fileName = null;

        string [] actions = null;
		bool flip = false;
        private void Start() {
            DoLoad();
        }

        void DoLoad() {
            SGK.ResourcesManager.LoadAsync(this, fileName, typeof(SkeletonDataAsset), (o) => {
				AfterLoad(skeletonAnimation, o as SkeletonDataAsset, actions, flip);
				BattlefieldObject Event = skeletonAnimation.gameObject.GetComponent<BattlefieldObject>();
				if(Event){
					Event.Start();
				}
            });
        }
    }

	public static class SkeletonAnimationExtension {
		public static void UpdateSkeletonAnimation(this SkeletonAnimation animation, string name, string[] actions = null, bool flip = false) {
			SkeletonAnimationLoader.Load(animation, name, actions, flip);
        }

        public static void UpdateSkeletonAnimation(this SkeletonGraphic animation, string name, string[] actions = null, string material = null) {
            SkeletonGraphicLoader.Load(animation, name, actions);
        }
    }
}
