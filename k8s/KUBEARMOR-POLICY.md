# KubeArmor Zero-Trust Security Policy for Wisecow

This document describes the KubeArmor security policies applied to the Wisecow application workload.

## Overview

KubeArmor is a cloud-native runtime security enforcement system that restricts the behavior of pods and containers at the system level. Two zero-trust policies have been implemented for the Wisecow application:

1. **wisecow-zero-trust-policy**: Comprehensive security restrictions
2. **wisecow-process-whitelist**: Additional process execution controls

## Policy Details

### 1. Process Execution Control

The policy allows ONLY the following executables to run:

- `/app/wisecow.sh` - Main application script
- `/usr/bin/fortune` - Fortune command for generating quotes
- `/usr/bin/cowsay` - Cowsay command for ASCII art
- `/bin/nc` or `/usr/bin/nc` - Netcat for network server
- `/bin/bash` and `/bin/sh` - Shell interpreters
- `/bin/cat`, `/bin/rm`, `/bin/mkfifo`, `/bin/sleep` - Basic utilities
- `/usr/bin/awk`, `/usr/bin/sed`, `/bin/echo` - Text processing utilities

**Violation Example**: Attempting to execute `/bin/curl` or `/usr/bin/wget` would be blocked as they are not in the whitelist.

### 2. File Access Restrictions

#### Allowed Read-Only Access:
- `/app/wisecow.sh` - Application script (read-only)
- `/usr/bin/` directory - System binaries (read-only)
- `/usr/share/games/fortunes/` - Fortune data files (read-only, recursive)
- `/etc/passwd` - User database (read-only)

#### Blocked Access:
- `/etc/shadow` - Shadow password file (blocked)
- `/root/` - Root home directory (blocked, recursive)
- `/etc/` - System configuration (blocked, recursive)
- `/var/run/` - Runtime data (blocked, recursive)
- `/sys/` - Kernel sysfs (blocked, recursive)
- `/proc/` - Process information (blocked, recursive)

**Violation Example**: Attempting `cat /etc/shadow` or `ls /root/` would be blocked by the policy.

### 3. Capability Restrictions

The following dangerous Linux capabilities are blocked:

- `sys_admin` - System administration operations
- `sys_ptrace` - Process tracing and debugging
- `sys_module` - Kernel module manipulation
- `dac_override` - Bypass file permission checks
- `chown` - Change file ownership

**Violation Example**: Attempts to load kernel modules or bypass file permissions would be blocked.

### 4. Execution from Writable Directories

Execution is blocked from temporary/writable directories:

- `/tmp/` (recursive)
- `/var/tmp/` (recursive)
- `/dev/shm/` (recursive)

**Violation Example**: Creating and executing a script in `/tmp/malicious.sh` would be blocked.

## Policy Enforcement Mode

Both policies use `action: Block`, meaning violations are actively prevented (not just logged).

## Testing and Violations

### Expected Policy Violations

The following actions should trigger policy violations:

1. **File Access Violation**:
   ```bash
   kubectl exec wisecow-pod -- cat /etc/shadow
   # Expected: Permission denied or operation blocked
   ```

2. **Directory Access Violation**:
   ```bash
   kubectl exec wisecow-pod -- ls /root/
   # Expected: Operation blocked
   ```

3. **Unauthorized Process Execution**:
   ```bash
   kubectl exec wisecow-pod -- /usr/bin/wget http://example.com
   # Expected: Execution blocked
   ```

4. **Execution from Temp Directory**:
   ```bash
   kubectl exec wisecow-pod -- sh -c 'echo "#!/bin/sh" > /tmp/test.sh && chmod +x /tmp/test.sh && /tmp/test.sh'
   # Expected: Execution blocked
   ```

## Deployment Information

- **KubeArmor Version**: 1.19.1
- **Cluster**: GKE Autopilot (wisecow-cluster)
- **Namespace**: default
- **Target Workload**: Pods with label `app: wisecow`
- **Enforcement**: Linux Security Modules (AppArmor/BPF-LSM)

## Monitoring

Policy violations can be monitored using:

```bash
# Using kArmor CLI
karmor logs --json | jq 'select(.PolicyName | contains("wisecow"))'

# Using kubectl
kubectl logs -n kubearmor -l kubearmor-app=kubearmor-relay --tail=100
```

## Zero-Trust Principles Applied

1. **Least Privilege**: Only explicitly allowed processes and files are accessible
2. **Default Deny**: Everything not explicitly allowed is blocked
3. **Process Whitelisting**: Only necessary executables can run
4. **File System Segmentation**: Sensitive directories are completely blocked
5. **Capability Restriction**: Dangerous Linux capabilities are denied

## Policy Files

- Location: `k8s/kubearmor-policy.yaml`
- Format: KubeArmor CRD (Custom Resource Definition)
- API Version: security.kubearmor.com/v1

## Conclusion

These zero-trust policies ensure that the Wisecow application runs with minimal privileges and maximum security. Any deviation from the expected behavior is blocked at the kernel level, providing strong runtime protection against compromised containers and malicious activity.
