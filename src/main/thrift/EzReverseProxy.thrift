/*   Copyright (C) 2013-2014 Computer Sciences Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. */

namespace java ezbake.reverseproxy.core.thrift
namespace py ezbake.reverseproxy
namespace cpp ezbake.ezreverseproxy.thrift
namespace rb EzReverseProxy
namespace js ezreverseproxy


include "ezbakeBaseTypes.thrift"
include "ezbakeBaseService.thrift"


const string SERVICE_NAME = "EzBakeFrontend"


# This is the structure that servers use to register with the reverse proxy.
# Registration is done via the addUpstreamServerRegistration method.
#
# The first server that registers using this structure is effectively
# registering the application. When registering multiple instances of a
# single application (typically for load balancing) ALL REGISTRATIONS
# MUST HAVE MATCHING UserFacingUrlPrefix, AppName, and UpstreamPath.
# Once a UserFacingUrlPrefix is registered, any further registrations
# of that prefix will be rejected if AppName and UpstreamPath do not
# match the values used in the first registration. Additionally,
# timeout and timeoutTries SHOULD also be identical, but that is
# not strictly required. Obviously, UpstreamHostAndPort should be
# different because the whole point is to register multiple upstream
# servers for reverse proxying. However, if a duplicate 
# UpstreamHostAndPort is registered, no error will occur.
#
# This structure is also used to remove upstream server registration
# in the removeUpstreamServerRegistration method. In that method, only
# the UserFacingUrlPrefix, AppName, and UpstreamHostAndPort are are required.
struct UpstreamServerRegistration {
    1: string UserFacingUrlPrefix
                      /* This is the server name and path that maps to your
                       * application. It must be unique to your application,
                       * and should be what you registered with the system.
                       * Do not prefix this with http:// or https://.
                       * This should typically be something like:
                       *      www.example.com/YourAppName/
                       * Though you'll need to use a server name that is
                       * valid for the project. Additionally, the path
                       * portion could be more complicated, but should
                       * be simple. Do not include query parameters in
                       * this prefix. */
    2: string AppName
                      /* The application name within EzBake it should
                       * probably be the same as the text in 1 folowing the
                       * first /  
                       * THIS VALUE MUST BE THE SAME FOR ALL REGISTRATIONS
                       * OF A SINGLE UserFacingUrlPrefix */
    3: string UpstreamHostAndPort
                      /* This is the hostname and port number on which the
                       * server to be reverse proxied runs. This should be
                       * of the form "FQHostname:port" or "IP:port". For
                       * example, "www.example.com:443" or "192.168.1.1:8080"*/
    4: string UpstreamPath
                      /* This is the path on the server to be proxied. This will
                       * often either be / or the same as the AppName. If the
                       * service to be proxied is at 192.168.1.1:8080/myApp/,
                       * the value specified here should be myApp/.
                       * THERE ARE SEVERAL IMPORTANT RESTRICTIONS HERE!!!
                       *     - the proxy will not automatically append
                       *       a trailing / character. If you need it,
                       *       append it explicitly.
                       *     - wildcard characters are not allowed
                       *     - adding query parameters *should* work here
                       *       but is not officially supported. 
                       *     - THIS PARAMETER MUST BE THE SAME FOR ALL
                       *       REGISTRATIONS OF A UserFacingUrlPrefix. */
    5: i32 timeout = 10
                      /* The web service at this UpstreamHostAndPort
                       * will be considered to have timed out
                       * if it does not respond within this many seconds. A
                       * reasonable value here is 10. 120 is the max allowed
                       * values <=0 are not allowed. */
    6: i32 timeoutTries = 1
                      /* NOT YET IMPLEMENTED - value is currently required but
                       * ignored. The text below is what to expect once this
                       * feature is implemented.

                       * If the web service at this UpstreamHostAndPort
                       * times out more than this many times
                       * (see timeout, above) it will be considered to be down
                       * and no requests will be sent to it until it
                       * reregisters with this service. A resonable value 
                       * for this is 3. The range of allowed values is:
                       * 1 <= timeoutTries <= 10Eventually */
    7: i32 uploadFileSize = 2
                      /* This value sets the maximum allowed size of file upload 
                       * in Mega bytes */ 
    8: bool sticky = false
                      /* If this flag is set (string True or False), the frontend will enable
                       * sticky sessions for a user. This is meaningless for all static
                       * content served by the frontend, as network load balancers are not 
                       * session-aware, and may route the session across multiple frontend
                       * instances */
    9: optional bool disableChunkedTransferEncoding = false
                      /* If this flag is set, the frontend will disable the support for chunked
                       * transfer encoding despite the HTTP/1.1 standards's requirement
                       */

}

/* A registration could not be removed by removeUpstreamServerRegistration
 * because the registration could not be found. Alternatively,
 * removeReverseProxiedPath() failed because no registrations were found
 * for that path */
exception RegistrationNotFoundException {
    1: string message
}

/* The registration could not be added because there is an existing
 * registration with the same UserFacingUrlPrefix but a different
 * AppName or UpstreamPath */
exception RegistrationMismatchException {
    1: string message
}

/* The registration could not be added because one or more of the
 * parameters was invalid */
exception RegistrationInvalidException {
    1: string message
}

service EzReverseProxy extends ezbakeBaseService.EzBakeBaseService {
    void addUpstreamServerRegistration(1:UpstreamServerRegistration registration) throws(1:RegistrationMismatchException eMismatch, 2:RegistrationInvalidException eInvalid)
    void removeUpstreamServerRegistration(1:UpstreamServerRegistration registration) throws (1:RegistrationNotFoundException eNotFound)
    void removeReverseProxiedPath(1:string UserFacingUrlPrefix) throws (1:RegistrationNotFoundException eNotFound)
    void removeAllProxyRegistrations()
    bool isUpstreamServerRegistered(1:UpstreamServerRegistration registration)
    bool isReverseProxiedPathRegistered(1:string UserFacingUrlPrefix)
    set<UpstreamServerRegistration> getAllUpstreamServerRegistrations()
    void shutdown()
}

