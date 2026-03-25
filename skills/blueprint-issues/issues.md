# Common OpenShift Deployment Issues - NVIDIA AI Blueprints

This document tracks recurring challenges encountered when deploying NVIDIA AI Blueprint applications on Red Hat OpenShift AI (RHOAI). For each issue encountered during OpenShift deployment, we document what the problem was and how it was resolved.

---

## Issue: Storage Permissions (Random UID)

**Category:** Security / Storage

### Description
OpenShift assigns a random UID (e.g. 1000660000) from a namespace-allocated range to each container, rather than using the UID defined in the image. If the container's data directory is owned by a different UID (as set during image build), the process cannot write to it and fails on startup with permission errors.

### Solution
Mount a Memory- or emptyDir-backed volume over the problematic path. OpenShift automatically sets GID 0 with group-write on emptyDir volumes, making them writable by any assigned UID.

Note: emptyDir data is lost on pod restart. Use PersistentVolumeClaims for production.

---

## Issue: Security Context Constraints (SCC)

**Category:** Security

### Description
OpenShift's default restricted-v2 SCC requires all containers to run as a UID within the namespace-assigned range. Sub-charts that hardcode specific UIDs (e.g. runAsUser: 7474) fail admission check.

### Solution
Create a dedicated service account and grant it the anyuid SCC. Assign only the affected services to that account - not the namespace-wide default.

---

## Issue: Hardcoded Security Contexts on GPU Containers

**Category:** Security

### Description
NIM and NeMo sub-charts are pre-configured with runAsUser: 1000, which conflicts with OpenShift's random UID allocation. Unlike databases that need their specific UID, these inference containers work fine under any UID - the hardcoded value just needs to be removed.

### Solution
Nullify the hardcoded security context fields in the Helm values override, allowing OpenShift to assign its own UID.

---

## Issue: GPU Node Scheduling (Tolerations)

**Category:** Scheduling

### Description
GPU nodes carry custom NoSchedule taints (e.g. nvidia.com/gpu=present:NoSchedule or cluster-specific keys). Without matching tolerations on GPU workloads, pods remain Pending indefinitely.

### Solution
Identify the taint keys on GPU nodes and pass them as configurable tolerations at deploy time. Build and apply tolerations dynamically in your deploy script so they are not hardcoded into the values file.

---

## Issue: Missing Pre-install Secrets

**Category:** Configuration

### Description
Helm charts reference secrets (image pull secrets, API keys, DB credentials) that must exist before helm install runs. The upstream charts provide no mechanism to create them, so pods fail with secret not found on startup.

### Solution
Pre-create all required secrets in the deploy script before calling helm upgrade --install.

---

## Issue: Shared Memory Limit (/dev/shm)

**Category:** Runtime / Stability

### Description
OpenShift's default /dev/shm is 64 MB. NVIDIA Triton Inference Server (used by NeMo) needs more for IPC between its processes, causing pod crashes under load with exit code 137.

### Solution
Mount a Memory-backed emptyDir at /dev/shm with a 2Gi size limit.

---

## Issue: Gated Model Downloads (HuggingFace Token)

**Category:** Configuration

### Description
Some models require license acceptance and a valid HF_TOKEN. When the token is missing, the download fails silently - the pod stays Running but never becomes ready.

### Solution
1. Accept the model license at huggingface.co with your account
2. Create a secret from the HuggingFace token and inject it as an env var into the affected pod

---

## Issue: Tokenizer Thread Pool Burst (Crash Loop)

**Category:** Runtime / Stability

### Description
Triton spawns multiple stub processes simultaneously at startup, each calling the HuggingFace tokenizer's encode(). The tokenizer uses a Rust-backed Rayon thread pool that defaults to one thread per CPU. On high-CPU nodes, this produces thousands of simultaneous pthread_create() calls. The Linux kernel returns EAGAIN to some, causing Rayon to panic. Pod enters a crash loop with 100–200+ restarts before stabilizing (or not).

### Solution
Set TOKENIZERS_PARALLELISM=false on NeMo containers to disable the tokenizer's internal parallelism.

---

## Issue: Guardrails False Positive on Smaller LLMs

**Category:** Functional

### Description
When using a smaller LLM (e.g. llama-3.1-8b-instruct) instead of the upstream default 70B model, the NeMo Guardrails component incorrectly classifies multi-image summarization requests as unsafe and blocks them.

### Solution
Disable guardrails via a Helm flag at deploy time. Core search, summarization, and alerting are unaffected.

---

## Issue: LLM Model Name Inconsistency

**Category:** Configuration

### Description
The LLM model name appears in multiple independent locations in the chart. Switching models without updating all of them causes 404 errors from the context manager and 401 errors when guardrails falls back to NVIDIA's cloud API.

### Solution
Propagate the model name from a single variable at deploy time using --set flags across all locations simultaneously.

---

## Issue: Insufficient GPU Resources (Pending Pods)

**Category:** Infrastructure / Scheduling

### Description
The upstream chart defaults are tuned for large GPU clusters - for example, the default LLM is a 70B model requiring 4 GPUs, and the VLM defaults to 2 GPUs. In GPU-constrained environments, this leaves multiple pods stuck in Pending with no available nodes to schedule them.

### Solution
Switch to a smaller LLM (llama-3.1-8b-instruct) that fits on 1 GPU, and override the VLM GPU count to 1 as well. These are exposed as configurable variables at deploy time:
- LLM_MODEL - the model name (must match in all chart locations, see issue 10)
- LLM_IMAGE / LLM_IMAGE_TAG - the corresponding NIM container image
- LLM_GPU_COUNT - GPUs allocated to the LLM pod
- VLM_GPU_COUNT - GPUs allocated to the VLM pod

---

## Issue: No Helm Chart in Blueprint - Must Build from Scratch

**Category:** Infrastructure

### Description
Some NVIDIA AI Blueprints (e.g. Multi-Agent-Intelligent-Warehouse) are Docker Compose-based with no Helm chart provided. Deploying on OpenShift requires authoring the entire chart from scratch - Deployments, Services, Secrets, and all OpenShift-specific overrides.

### Solution
Build a Helm chart from the Docker Compose definition, mapping each service to a Kubernetes Deployment or StatefulSet, and apply all OpenShift adaptations (SCCs, tolerations, security contexts, secrets) during authoring.

---

## Issue: NVIDIA Embedding Model Dual-Mode Requirement (RAG Pipeline)

**Category:** RAG / Embeddings

### Description
Some of NVIDIA's embedding models (e.g., nv-embedqa-e5-v5) require different modes for different operations: input_type="passage" for indexing/embedding documents and input_type="query" for searching/embedding user queries. Using the wrong mode causes "large drops in retrieval accuracy" per NVIDIA documentation.

NVIDIA's native NVIDIAEmbeddings client class supports both automatic input_type switching AND custom base_url for self-hosted NIMs. However, when using frameworks like embedchain (used by CrewAI tools and similar frameworks), the embedding client is created internally using NvidiaEmbedder, which lacks base_url support for self-hosted deployments. This prevents you from using the native client's automatic mode switching, and you must use the OpenAI-compatible API with model name suffixes instead:
- nvidia/nv-embedqa-e5-v5-passage - For document indexing
- nvidia/nv-embedqa-e5-v5-query - For user query searches

### Solution
Configure your RAG pipeline to use different model name suffixes for each operation:

```python
# For indexing: use -passage suffix
model_name = "nvidia/nv-embedqa-e5-v5-passage"

# For querying: use -query suffix
model_name = "nvidia/nv-embedqa-e5-v5-query"
```

Special case - ChromaDB: ChromaDB sets the embedding function once at collection creation and doesn't provide a function to change it. After indexing with -passage mode, directly replace the private attribute:

```python
chromadb_collection._embedding_function = embedding_function  # Switch to -query mode
```

Alternative approach: If your application requires frequent embedding mode switching, consider inheriting from NvidiaEmbedder and adding base_url parameter support, allowing you to use NVIDIAEmbeddings with its native input_type switching capability for self-hosted NIMs.

Note: When you control client instantiation directly (not through embedchain), use NVIDIAEmbeddings with custom base_url to leverage automatic mode switching and avoid manual mode management.

---

## Issue: ChromaDB SQLite Version Incompatibility in RHOAI

**Category:** RAG / Embeddings

### Description
RHOAI environments ship with SQLite 3.34, but ChromaDB requires SQLite version 3.35 or higher. When attempting to use ChromaDB for vector storage in RHOAI workbenches or deployments, this version mismatch causes import errors or runtime failures when ChromaDB tries to initialize its database.

### Solution
Redirect Python's sqlite3 module to use pysqlite3-binary instead, which bundles a newer SQLite version (3.51). Add this patch at the top of your script before importing ChromaDB:

```python
# SQLite patch: RHOAI uses SQLite 3.34 but ChromaDB needs 3.35+
# This redirects Python to use pysqlite3-binary (bundled SQLite 3.51)
import sys
__import__('pysqlite3')
sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')
```

Ensure pysqlite3-binary is installed in your environment:
```bash
pip install pysqlite3-binary
```

---


