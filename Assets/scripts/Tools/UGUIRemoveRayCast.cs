using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UGUIRemoveRayCast : MonoBehaviour
{
    public void RemoveAll()
    {
        //Image
        Graphic[] graphic =  transform.GetComponentsInChildren<Graphic>();

        foreach (var item in graphic)
        {
            item.raycastTarget = false;
        }
        GameObject.DestroyImmediate(this);

    }
}
