---
name: blueprint-issues
description: Search team common issues for RHOAI/NVIDIA deployments based on conversation context or search terms.
disable-model-invocation: true
allowed-tools: "Read(issues.md)"
argument-hint: "[search terms]"
---

# Team Common Issues

Common issues and solutions for NVIDIA blueprint deployments on OpenShift AI.

**Usage:**
- `/blueprint-issues` - Search based on current conversation context
- `/blueprint-issues GPU` - Search for GPU-related issues
- Ask: "Check team issues for storage problems"

The issues are loaded from `issues.md` in this directory and filtered based on your context or search terms.
