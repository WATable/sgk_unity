/*  This file is part of the "NavMesh Extension" project by Rebound Games.
 *  You are only allowed to use these resources if you've bought them directly or indirectly
 *  from Rebound Games. You shall not license, sublicense, sell, resell, transfer, assign,
 *  distribute or otherwise make available to any third party the Service or the Content. 
 */

using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace NavMeshExtension
{
    /// <summary>
    /// Portal Object Editor for moving portals and drawing connections between them.
    /// <summary>
    [CustomEditor(typeof(NavMeshLinkVisualizer))]
    public class NavMeshLinkVisualizerEditor : Editor
    {
        //portal object reference
        private NavMeshLinkVisualizer script;


        void OnEnable()
        {
            script = (NavMeshLinkVisualizer)target;
			script.navLink = script.GetComponent<UnityEngine.AI.NavMeshLink>();
        }


        /// <summary>
        /// Custom inspector override for portal properties.
        /// </summary>
        public override void OnInspectorGUI()
        {
			DrawDefaultInspector();

			EditorGUILayout.LabelField("Distance: " + Vector3.Distance(script.navLink.startPoint, script.navLink.endPoint));
			script.UpdatePositions();
        }
    }
}
