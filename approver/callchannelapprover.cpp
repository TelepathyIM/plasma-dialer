/*
 * <one line to give the library's name and an idea of what it does.>
 * Copyright 2020  <copyright holder> <email>
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) version 3, or any
 * later version accepted by the membership of KDE e.V. (or its
 * successor approved by the membership of KDE e.V.), which shall
 * act as a proxy defined in Section 6 of version 3 of the license.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "callchannelapprover.h"

#include <KLocalizedString>

#include <TelepathyQt/PendingReady>
#include <TelepathyQt/ChannelClassSpec>
#include <TelepathyQt/ClientRegistrar>
#include <TelepathyQt/CallChannel>

CallChannelApprover::CallChannelApprover(const Tp::CallChannelPtr & channel, QObject *parent)
    : ChannelApprover(parent)
{
    if (!channel.isNull()) {
        Tp::PendingReady *pendingReady = channel->becomeReady(Tp::Features()
                                                            << Tp::CallChannel::FeatureCore
                                                            << Tp::CallChannel::FeatureCallState);
        m_Channels[pendingReady] = channel;
        connect(pendingReady, &Tp::PendingOperation::finished, 
                this, &CallChannelApprover::onChannelReady);
    }
}

CallChannelApprover::~CallChannelApprover()
{
    deleteLater();
}

void CallChannelApprover::onChannelReady(Tp::PendingOperation* op)
{
    auto *pendingReady = qobject_cast<Tp::PendingReady *>(op);
    if (!pendingReady || !m_Channels.contains(pendingReady)) {
        qWarning() << "Pending operation is not tracked" << op;
        return;
    }
    
    Tp::ChannelPtr channel = m_Channels.value(pendingReady);
    Tp::CallChannelPtr callChannel = Tp::CallChannelPtr::dynamicCast(channel);
    
    if (channel->initiatorContact() != channel->connection()->selfContact()
        && callChannel->callState() == Tp::CallStateInitialised
        && !callChannel->isRequested()) {
        callChannel->setRinging();
    }
    
    QStringList actions;
    actions << i18n("Accept") << i18n("Reject");
    if(!m_ringingNotification) {
        m_ringingNotification = new KNotification(QStringLiteral("ringing"), KNotification::Persistent | KNotification::LoopSound, nullptr);
    }
    m_ringingNotification->setComponentName(QStringLiteral("plasma_dialer"));
    m_ringingNotification->setIconName(QStringLiteral("call-start"));
    m_ringingNotification->setTitle(QStringLiteral("Incoming call"));
    m_ringingNotification->setText(callChannel->targetContact()->alias());
    // this will be used by the notification applet to show custom notification UI
    // with swipe decision.
    m_ringingNotification->setHint(QStringLiteral("category"), "x-kde.incoming-call");
    m_ringingNotification->setActions(actions);
    m_ringingNotification->sendEvent();
    
    void (KNotification::* activation)(unsigned int) = &KNotification::activated;
    connect(m_ringingNotification, activation,
            this, &CallChannelApprover::onNotificationAction);
}

void CallChannelApprover::onNotificationAction(unsigned int action)
{
    switch(action) {
        case 1:
            // call accepted
            emit channelAccepted();
            break;
        case 2:
            // call rejected
            emit channelRejected();
            break;
        default:
            Q_UNREACHABLE();
            break;
    }
}


