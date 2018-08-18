/*  This file is part of the "NavMesh Extension" project by Rebound Games.
 *  You are only allowed to use these resources if you've bought them directly or indirectly
 *  from Rebound Games. You shall not license, sublicense, sell, resell, transfer, assign,
 *  distribute or otherwise make available to any third party the Service or the Content. 
 */

using UnityEngine;
using UnityEngine.AI;
using UnityEditor;

namespace NavMeshExtension
{
    /// <summary>
    /// Adds a new Portal Manager gameobject to the scene.
    /// <summary>
    [CustomEditor(typeof(NavMeshManager))]
    public class NavMeshManagerEditor : Editor
    {
        //manager reference
        private NavMeshManager script;


        void OnEnable()
        {
            script = (NavMeshManager)target;
        }


        /// <summary>
        /// Custom inspector override for buttons.
        /// </summary>
        public override void OnInspectorGUI()
        {
            DrawDefaultInspector();
            EditorGUILayout.Space();

            if (GUILayout.Button("New NavMesh"))
            {
                CreateNewNavMesh();
                GetSceneView().Focus();
            }

            if (GUILayout.Button("New Not Walkable NavMesh"))
            {
                CreateNewNavMesh(false);
                GetSceneView().Focus();
            }

            if (GUILayout.Button("Toggle Renderers"))
            {
                //invert boolean and toggle all renderers
                script.rendererToggle = !script.rendererToggle;
                MeshRenderer[] renderers = script.GetComponentsInChildren<MeshRenderer>(true);

                for (int i = 0; i < renderers.Length; i++)
                    renderers[i].enabled = script.rendererToggle;
            }

			EditorGUILayout.Space();
            GUILayout.Box("Note: Only visible renderers will be considered when baking NavMesh.");
        }


        /// <summary>
        /// Creates a new gameobject to use it as NavMeshObject.
        /// </summary>
        public void CreateNewNavMesh(bool walkable = true)
        {
            //create gameobject
            GameObject navGO = new GameObject(walkable ? "New Walkable NavMesh" : "New Not Walkable NavMesh");
            navGO.transform.parent = script.transform;
            navGO.isStatic = true;
            navGO.AddComponent<NavMeshObject>();
            NavMeshModifier modifier = navGO.AddComponent<NavMeshModifier>();
            if (!walkable) {
                modifier.overrideArea = true;
                modifier.area = 1;
            }

            //modify renderer to ignore shadows
            MeshRenderer mRenderer = navGO.GetComponent<MeshRenderer>();
            #if UNITY_4_6 || UNITY_4_7
            mRenderer.castShadows = false;
            #else
            mRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            #endif
            mRenderer.receiveShadows = false;
            if (script.meshMaterial)
                mRenderer.sharedMaterial = script.meshMaterial;
            else
                mRenderer.enabled = false;

            Undo.RegisterCreatedObjectUndo(navGO, "Created NavMesh");
            Selection.activeGameObject = navGO;
        }


        /// <summary>
        /// Gets the active SceneView or creates one.
        /// </summary>
        public static SceneView GetSceneView()
        {
            SceneView view = SceneView.currentDrawingSceneView;
            if (view == null)
                view = EditorWindow.GetWindow<SceneView>();

            return view;
        }
    }
}
