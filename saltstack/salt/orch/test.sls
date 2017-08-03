own_stack.test:
  salt.function:
    - name: state.highstate
    - tgt: 'dev-web-1g'
