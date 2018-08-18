﻿using UnityEngine.UI;
using UnityEngine;

namespace SGK
{
    [RequireComponent(typeof(Text))]

    public class NonBreakingSpaceText : MonoBehaviour
    {
        public static readonly string no_breaking_space = "\u00A0";

        protected Text text;
        // Use this for initialization
        void Awake()
        {
            text = this.GetComponent<Text>();
            text.RegisterDirtyVerticesCallback(OnTextChange);
        }

        public void OnTextChange()
        {
            if (text.text.Contains(" "))
            {
                text.text = text.text.Replace(" ", no_breaking_space);
            }
        }

    }
}
