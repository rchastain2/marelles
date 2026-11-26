/***************************************************************************
  This file is part of Morris.
  Copyright (C) 2026 Dirk Farin <dirk.farin@gmail.com>

  Morris is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
***************************************************************************/

#ifndef SIGNAL_HH
#define SIGNAL_HH

#include <algorithm>
#include <functional>
#include <memory>
#include <utility>
#include <vector>


/* A handle for one connected slot, returned by Signal::connect().
   Default-constructed connections are empty and safe to disconnect.
   Disconnecting also stays safe after the signal itself has been
   destroyed, because the connection only holds a weak reference.
*/
class Connection
{
public:
  Connection() = default;

  void disconnect()
  {
    std::shared_ptr<bool> connected = m_connected.lock();
    if (connected)
      {
	*connected = false;
      }
  }

private:
  explicit Connection(const std::shared_ptr<bool>& connected) : m_connected(connected) { }

  std::weak_ptr<bool> m_connected;

  template <class Signature> friend class Signal;
};


/* A minimal signal/slot implementation covering what this program needs:
   connecting slots, emitting to them in the order they were connected, and
   disconnecting a single slot again.

   Not thread-safe by design. Every signal here is emitted on the GUI thread;
   the search threads talk to the application through the ThreadTunnel instead.

   One deliberate difference from boost::signals2, which this replaced:
   disconnecting only marks the slot dead, so whatever the slot captured is
   released at the next emission rather than immediately.
*/
template <class Signature> class Signal;

template <class... Args>
class Signal<void (Args...)>
{
public:
  using Slot = std::function<void (Args...)>;

  Signal() = default;

  // Signals identify an object and are not value types.
  Signal(const Signal&) = delete;
  Signal& operator=(const Signal&) = delete;

  Connection connect(Slot slot)
  {
    Entry entry;
    entry.connected = std::make_shared<bool>(true);
    entry.slot = std::move(slot);

    m_slots.push_back(std::move(entry));

    return Connection(m_slots.back().connected);
  }

  void operator()(Args... args)
  {
    // Drop what was disconnected since the previous emission.
    m_slots.erase(std::remove_if(m_slots.begin(), m_slots.end(), isDisconnected),
		  m_slots.end());

    /* Emit from a copy. A slot is allowed to connect further slots, to
       disconnect itself, and even to destroy the object that owns this
       signal, none of which may disturb the emission in progress. */
    std::vector<Entry> slots = m_slots;

    for (size_t i=0; i<slots.size(); i++)
      {
	if (*(slots[i].connected))
	  {
	    slots[i].slot(args...);
	  }
      }
  }

  bool empty() const
  {
    for (size_t i=0; i<m_slots.size(); i++)
      {
	if (*(m_slots[i].connected)) { return false; }
      }

    return true;
  }

private:
  struct Entry
  {
    std::shared_ptr<bool> connected;
    Slot                  slot;
  };

  static bool isDisconnected(const Entry& e) { return !*(e.connected); }

  std::vector<Entry> m_slots;
};

#endif
