#cloud-config

---
write-files:
  - path: /opt/bin/wupiao
    permissions: '0755'
    content: |
      #!/bin/bash
      # [w]ait [u]ntil [p]ort [i]s [a]ctually [o]pen
      [ -n "$1" ] && [ -n "$2" ] && while ! curl --output /dev/null \
        --silent --head --fail \
        http://$${1}:$${2}; do sleep 1 && echo -n .; done;
      exit $?
  - path: /opt/kubeconfig
    permissions: 0755
    content: |
      apiVersion: v1
      kind: Config
      clusters:
      - cluster:
          server: ${master_url}
          insecure-skip-tls-verify: true
        name: kubernetes
      contexts:
      - context:
          cluster: kubernetes
          user: kubelet
        name: kubelet
      current-context: kubelet
      users:
        - name: kubelet
          user:
            token: kubelet
coreos:
  units:
    - name: format-ephemeral.service
      command: start
      content: |
        [Unit]
        Description=Formats the ephemeral drive
        After=dev-xvdf.device
        Requires=dev-xvdf.device
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/usr/sbin/wipefs -f /dev/xvdf
        ExecStart=/usr/sbin/mkfs.ext4 -F /dev/xvdf
    - name: var-lib-docker.mount
      command: start
      content: |
        [Unit]
        Description=Mount ephemeral to /var/lib/docker
        Requires=format-ephemeral.service
        After=format-ephemeral.service
        [Mount]
        What=/dev/xvdf
        Where=/var/lib/docker
        Type=ext4
    - name: docker.service
      command: start
      drop-ins:
        - name: 10-wait-docker.conf
          content: |
            [Unit]
            After=var-lib-docker.mount
            Requires=var-lib-docker.mount
    - name: setup-network-environment.service
      command: start
      content: |
        [Unit]
        Description=Setup Network Environment
        Documentation=https://github.com/kelseyhightower/setup-network-environment
        Requires=network-online.target
        After=network-online.target

        [Service]
        ExecStartPre=-/usr/bin/mkdir -p /opt/bin
        ExecStartPre=/usr/bin/curl -L -o /opt/bin/setup-network-environment -z /opt/bin/setup-network-environment https://github.com/kelseyhightower/setup-network-environment/releases/download/v1.0.0/setup-network-environment
        ExecStartPre=/usr/bin/chmod +x /opt/bin/setup-network-environment
        ExecStart=/opt/bin/setup-network-environment
        RemainAfterExit=yes
        Type=oneshot
    - name: kube-proxy.service
      command: start
      content: |
        [Unit]
        Description=Kubernetes Proxy
        Documentation=https://github.com/kubernetes/kubernetes
        Requires=setup-network-environment.service
        After=setup-network-environment.service

        [Service]
        ExecStartPre=/usr/bin/curl -L -o /opt/bin/kube-proxy -z /opt/bin/kube-proxy ${kube-proxy-binary}
        ExecStartPre=/usr/bin/chmod +x /opt/bin/kube-proxy
        # wait for kubernetes master to be up and ready
        ExecStart=/opt/bin/kube-proxy \
        --kubeconfig=/opt/kubeconfig \
        --v=2 \
        --logtostderr=true
        Restart=always
        RestartSec=10
    - name: kube-kubelet.service
      command: start
      content: |
        [Unit]
        Description=Kubernetes Kubelet
        Documentation=https://github.com/kubernetes/kubernetes
        Requires=setup-network-environment.service
        After=setup-network-environment.service

        [Service]
        EnvironmentFile=/etc/environment
        ExecStartPre=/usr/bin/curl -L -o /opt/bin/kubelet -z /opt/bin/kubelet ${kube-kubelet-binary}
        ExecStartPre=/usr/bin/chmod +x /opt/bin/kubelet
        # wait for kubernetes master to be up and ready
        ExecStart=/opt/bin/kubelet \
        --address=0.0.0.0 \
        --port=10250 \
        --api-servers=${master_url} \
        --allow-privileged=true \
        --hostname-override=$${COREOS_PUBLIC_IPV4} \
        --logtostderr=true \
        --kubeconfig=/opt/kubeconfig \
        --cluster-dns=10.100.0.2 \
        --cluster-domain=cluster.local \
        --cadvisor-port=4194 \
        --healthz-bind-address=0.0.0.0 \
        --healthz-port=10248 \
        --v=2
        Restart=always
        RestartSec=10
  update:
    group: beta
    reboot-strategy: off
