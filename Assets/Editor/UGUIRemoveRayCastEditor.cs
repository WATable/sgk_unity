using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(UGUIRemoveRayCast))]
public class UGUIRemoveRayCastEditor : Editor {
    public override void OnInspectorGUI()
    {

        UGUIRemoveRayCast refs = (UGUIRemoveRayCast)serializedObject.targetObject;
        if (GUILayout.Button("remove all raycast)"))
        {
            refs.RemoveAll();
            return;
        }

        base.OnInspectorGUI();
    }
}
