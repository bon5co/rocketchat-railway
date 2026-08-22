# Rocket.Chat 7.10.0, pinned by digest, with the literal settings baked in so the
# template ships no blank required variables.
FROM registry.rocket.chat/rocketchat/rocket.chat@sha256:64058d062f2e08c2ca0d4dc1d94b249b5b6525c872c4cce7dde7221e484a7f84
ENV DEPLOY_METHOD=docker \
    DEPLOY_PLATFORM=railway \
    NODE_ENV=production \
    NODE_OPTIONS=--max-old-space-size=768 \
    Accounts_RegistrationForm="Secret URL" \
    OVERWRITE_SETTING_Show_Setup_Wizard=completed
