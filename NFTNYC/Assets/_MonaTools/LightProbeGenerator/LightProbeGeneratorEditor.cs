#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.IMGUI.Controls;

namespace Mona
{
    [CustomEditor(typeof(LightProbeGenerator))]
    public class LightProbeGeneratorEditor : Editor
    {

        SerializedProperty bBoxCenter;
        SerializedProperty bBoxSize;
        SerializedProperty mergeDistance;
        SerializedProperty useNavMeshPlacement;
        SerializedProperty useObjectBoundsPlacement;
        SerializedProperty useVolumeScatterPlacement;
        SerializedProperty useRayCastPlacement;
        SerializedProperty generationResolution;

        private LightProbeGenerator lightProbeGenerator;
        void OnEnable()
        {
            lightProbeGenerator = (LightProbeGenerator)target;
            useNavMeshPlacement = serializedObject.FindProperty("useNavMeshPlacement");
            useObjectBoundsPlacement = serializedObject.FindProperty("useObjectBoundsPlacement");
            useVolumeScatterPlacement = serializedObject.FindProperty("useVolumeScatterPlacement");
            useRayCastPlacement = serializedObject.FindProperty("useRayCastPlacement");
            bBoxCenter = serializedObject.FindProperty("bBoxCenter");
            bBoxSize = serializedObject.FindProperty("bBoxSize");
            generationResolution = serializedObject.FindProperty("generationResolution");
            mergeDistance = serializedObject.FindProperty("mergeDistance");
        }

        public override void OnInspectorGUI()
        {
            Texture banner = (Texture)AssetDatabase.LoadAssetAtPath("Assets/_MonaTools/LightProbeGenerator/Resources/LightProbeGeneratorBanner.png", typeof(Texture));
            if (banner)
            {
                GUI.DrawTexture(new Rect(0, 0, 498, 66), banner, ScaleMode.ScaleToFit, false);
            }
            GUILayout.Space(66);

            EditorGUILayout.PropertyField(bBoxCenter, new GUIContent("Center", "The position of the Light Probe Volume in the GameObject’s local space."));
            EditorGUILayout.PropertyField(bBoxSize, new GUIContent("Size", "The size of the Light Probe Volume in the X, Y, Z dimensions."));

            GUILayout.Space(20);

            GUILayout.BeginHorizontal();
            {
                EditorGUILayout.PropertyField(useNavMeshPlacement, new GUIContent("NavMeshPlacement", "Creates a navmesh and uses it to generate probe positions. This placement method is useful for generating probes in areas most player avatars will traverse."));
                EditorGUILayout.PropertyField(useRayCastPlacement, new GUIContent("RayCastPlacement", "Traces the light rays of point and spot lights to find probes locations in the scene."));
            }
            GUILayout.EndHorizontal();
            GUILayout.BeginHorizontal();
            {
                EditorGUILayout.PropertyField(useVolumeScatterPlacement, new GUIContent("VolumeScatterPlacement", "Scatters a uniform grid of probes inside the set volume."));
                EditorGUILayout.PropertyField(useObjectBoundsPlacement, new GUIContent("ObjectBoundsPlacement", "Places probes on the bounding box corners of objects."));
            }
            GUILayout.EndHorizontal();
            EditorGUILayout.PropertyField(generationResolution, new GUIContent("Placement Density", "Controls the density of the Light Probe Group generation, a lower value means more Probes per unit. This only effects the volume scatter and raycast placement methods."));

            GUILayout.Space(20);

            GUI.enabled = true;
            if (lightProbeGenerator.transform.position != new Vector3(0f,0f,0f))
            {
                EditorGUILayout.HelpBox("This GameObject's tranform position must be at the local origin position (0,0,0) for the tool to function properly.", MessageType.Error);
                GUI.enabled = false;
            }
            if (lightProbeGenerator.transform.localScale != new Vector3(1,1,1))
            {
                EditorGUILayout.HelpBox("This GameObject's tranform scale must be uniform (1,1,1) for the tool to function properly.", MessageType.Error);
                GUI.enabled = false;
            }
            if (GUILayout.Button("Generate"))
            {
                lightProbeGenerator.transform.position = new Vector3(0,0,0);
                lightProbeGenerator.transform.localScale = new Vector3(1,1,1);
                lightProbeGenerator.Generate();
            }
            EditorGUILayout.HelpBox("Light probes will be generated within the specified volume using the selected placement methods. When this object is selected the volume will be highlighted as a cube with a cyan wireframe in the scene view.", MessageType.Info);

            GUILayout.Space(20);

            GUI.enabled = true;
            if (!lightProbeGenerator.gameObject.GetComponent<LightProbeGroup>())
            {
                EditorGUILayout.HelpBox("You must first have a LightProbeGroup component before optimizing - generate one, or manually create one before proceeding.", MessageType.Warning);
                GUI.enabled = false;
            }
            EditorGUILayout.PropertyField(mergeDistance, new GUIContent("Merge Distance", "Sets strength of the Optimizer, the value determines the maximum distance probes can be merged (higher values mean more probes)."));
            if (GUILayout.Button("Optimize"))
            {
                lightProbeGenerator.OptimizeProbes();
            }
            GUI.enabled = true;
            if (lightProbeGenerator.gameObject.GetComponent<LightProbeGroup>())
            {
                EditorGUILayout.HelpBox("Optimizes the LightProbeGroup by removing unnecessary LightProbes from the group.", MessageType.Info);
            }

            serializedObject.ApplyModifiedProperties();
        }
    }
}
#endif